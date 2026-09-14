#!/usr/bin/env bash
# weather-fetch.sh — current conditions + 7-day forecast via Open-Meteo
#
# wttr.in IP lookup currently returns "location not found" (server-side),
# so this resolves lat/lon ourselves and queries Open-Meteo (no API key).
#
# Usage:
#   weather-fetch.sh --hud     # "☁|24°"  (center-bar HUD)
#   weather-fetch.sh --json    # wttr-shaped JSON (dashboard / lock)
#
# Location (first match wins):
#   WEATHER_LAT / WEATHER_LON [/ WEATHER_CITY]
#   $XDG_CONFIG_HOME/astral-vagabond/weather-location  (lat= lon= city=)
#   cached IP geolocation (~24h), then ipinfo.io / ip-api.com

set -euo pipefail

MODE="json"
case "${1:-}" in
    --hud|-h)   MODE="hud"  ;;
    --json|-j)  MODE="json" ;;
    --help)
        sed -n '2,16p' "$0" | sed 's/^# \?//'
        exit 0
        ;;
    "")
        MODE="json"
        ;;
    *)
        echo "error: unknown option '$1' (try --help)" >&2
        exit 1
        ;;
esac

TIMEOUT="${WEATHER_TIMEOUT:-10}"
UA="astral-vagabond-weather"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/astral-vagabond"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/astral-vagabond"
LOC_CACHE="${CACHE_DIR}/weather-location"
LOC_CONFIG="${CONFIG_DIR}/weather-location"
LOC_TTL=86400

mkdir -p "$CACHE_DIR"

curl_get() {
    curl -fsS --connect-timeout 5 --max-time "$TIMEOUT" -A "$UA" "$1" 2>/dev/null || true
}

read_kv_file() {
    # Reads lat= lon= city= from a file into LAT LON CITY (if unset).
    local file="$1"
    [[ -f "$file" ]] || return 1
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line//[[:space:]]/}" ]] && continue
        key="${line%%=*}"
        val="${line#*=}"
        key="$(echo "$key" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
        val="$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$key" in
            lat|latitude)  LAT="${LAT:-$val}" ;;
            lon|lng|longitude) LON="${LON:-$val}" ;;
            city|name)     CITY="${CITY:-$val}" ;;
        esac
    done < "$file"
    [[ -n "${LAT:-}" && -n "${LON:-}" ]]
}

valid_coord() {
    # Rough range check so we never send junk to Open-Meteo.
    awk -v lat="$1" -v lon="$2" 'BEGIN {
        if (lat == "" || lon == "") exit 1
        if (lat + 0 != lat || lon + 0 != lon) exit 1
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) exit 1
        exit 0
    }'
}

write_loc_cache() {
    mkdir -p "$CACHE_DIR"
    cat > "$LOC_CACHE" <<EOF
lat=${LAT}
lon=${LON}
city=${CITY:-}
EOF
}

lookup_ip_location() {
    local json lat lon city loc

    json="$(curl_get "https://ipinfo.io/json")"
    if [[ -n "$json" ]]; then
        loc="$(echo "$json" | jq -r '.loc // empty' 2>/dev/null || true)"
        city="$(echo "$json" | jq -r '.city // empty' 2>/dev/null || true)"
        if [[ "$loc" == *,* ]]; then
            lat="${loc%%,*}"
            lon="${loc##*,}"
            if valid_coord "$lat" "$lon"; then
                LAT="$lat"
                LON="$lon"
                CITY="${city:-}"
                return 0
            fi
        fi
    fi

    json="$(curl_get "http://ip-api.com/json/?fields=status,lat,lon,city")"
    if [[ -n "$json" ]]; then
        lat="$(echo "$json" | jq -r 'select(.status=="success") | .lat' 2>/dev/null || true)"
        lon="$(echo "$json" | jq -r 'select(.status=="success") | .lon' 2>/dev/null || true)"
        city="$(echo "$json" | jq -r 'select(.status=="success") | .city // empty' 2>/dev/null || true)"
        if [[ -n "$lat" && -n "$lon" && "$lat" != "null" && "$lon" != "null" ]] \
                && valid_coord "$lat" "$lon"; then
            LAT="$lat"
            LON="$lon"
            CITY="${city:-}"
            return 0
        fi
    fi
    return 1
}

resolve_location() {
    LAT="${WEATHER_LAT:-}"
    LON="${WEATHER_LON:-}"
    CITY="${WEATHER_CITY:-}"

    if [[ -n "$LAT" && -n "$LON" ]] && valid_coord "$LAT" "$LON"; then
        return 0
    fi

    LAT=""; LON=""; CITY="${WEATHER_CITY:-}"
    if read_kv_file "$LOC_CONFIG" && valid_coord "$LAT" "$LON"; then
        return 0
    fi

    LAT=""; LON=""; CITY="${WEATHER_CITY:-}"
    if [[ -f "$LOC_CACHE" ]]; then
        local now mtime age
        now="$(date +%s)"
        mtime="$(stat -c %Y "$LOC_CACHE" 2>/dev/null || echo 0)"
        age=$(( now - mtime ))
        if (( age < LOC_TTL )) && read_kv_file "$LOC_CACHE" && valid_coord "$LAT" "$LON"; then
            return 0
        fi
    fi

    LAT=""; LON=""; CITY="${WEATHER_CITY:-}"
    if lookup_ip_location; then
        write_loc_cache
        return 0
    fi
    return 1
}

if ! resolve_location; then
    if [[ "$MODE" == "json" ]]; then
        echo "{}"
    fi
    exit 1
fi

URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,apparent_temperature&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=7&timezone=auto"

RAW="$(curl_get "$URL")"
if [[ -z "$RAW" ]]; then
    if [[ "$MODE" == "json" ]]; then
        echo "{}"
    fi
    exit 1
fi

export WEATHER_CITY_OUT="${CITY:-}"

if [[ "$MODE" == "hud" ]]; then
    echo "$RAW" | jq -er --arg city "$WEATHER_CITY_OUT" '
        def emoji(c):
            if c == 0 or c == 1 then "☀"
            elif c == 2 then "⛅"
            elif c == 3 then "☁"
            elif c == 45 or c == 48 then "fog"
            elif c == 51 or c == 53 or c == 55 or c == 80 or c == 81 or c == 82 then "🌦"
            elif c == 61 or c == 63 or c == 65 then "🌧"
            elif c == 56 or c == 57 or c == 66 or c == 67 or c == 71 or c == 73 or c == 75 or c == 77 or c == 85 or c == 86 then "❄"
            elif c == 95 or c == 96 or c == 99 then "⛈"
            else "*" end;
        select(.current.temperature_2m != null) |
        "\(emoji(.current.weather_code))|\(.current.temperature_2m | round)°"
    ' 2>/dev/null || true
    exit 0
fi

echo "$RAW" | jq -e --arg city "$WEATHER_CITY_OUT" '
    def emoji(c):
        if c == 0 or c == 1 then "☀"
        elif c == 2 then "⛅"
        elif c == 3 then "☁"
        elif c == 45 or c == 48 then "fog"
        elif c == 51 or c == 53 or c == 55 or c == 80 or c == 81 or c == 82 then "🌦"
        elif c == 61 or c == 63 or c == 65 then "🌧"
        elif c == 56 or c == 57 or c == 66 or c == 67 or c == 71 or c == 73 or c == 75 or c == 77 or c == 85 or c == 86 then "❄"
        elif c == 95 or c == 96 or c == 99 then "⛈"
        else "*" end;
    def desc(c):
        if c == 0 then "Clear"
        elif c == 1 then "Mainly clear"
        elif c == 2 then "Partly cloudy"
        elif c == 3 then "Overcast"
        elif c == 45 or c == 48 then "Fog"
        elif c == 51 then "Light drizzle"
        elif c == 53 then "Drizzle"
        elif c == 55 then "Heavy drizzle"
        elif c == 56 or c == 57 then "Freezing drizzle"
        elif c == 61 then "Light rain"
        elif c == 63 then "Rain"
        elif c == 65 then "Heavy rain"
        elif c == 66 or c == 67 then "Freezing rain"
        elif c == 71 then "Light snow"
        elif c == 73 then "Snow"
        elif c == 75 then "Heavy snow"
        elif c == 77 then "Snow grains"
        elif c == 80 then "Light showers"
        elif c == 81 then "Showers"
        elif c == 82 then "Heavy showers"
        elif c == 85 then "Light snow showers"
        elif c == 86 then "Heavy snow showers"
        elif c == 95 then "Thunderstorm"
        elif c == 96 or c == 99 then "Thunderstorm + hail"
        else "—" end;
    select(.current.temperature_2m != null) |
    .daily as $d |
    {
      current_condition: [{
        weatherDesc: [{value: desc(.current.weather_code)}],
        weatherEmoji: emoji(.current.weather_code),
        weatherCode: (.current.weather_code | tostring),
        temp_C: (.current.temperature_2m | round | tostring),
        FeelsLikeC: (.current.apparent_temperature | round | tostring),
        humidity: (.current.relative_humidity_2m | round | tostring),
        windspeedKmph: (.current.wind_speed_10m | round | tostring)
      }],
      nearest_area: (if $city == "" then [] else [{areaName: [{value: $city}]}] end),
      weather: [
        range(0; ($d.time | length)) |
        {
          date: $d.time[.],
          maxtempC: ($d.temperature_2m_max[.] | round | tostring),
          mintempC: ($d.temperature_2m_min[.] | round | tostring),
          hourly: [{
            weatherCode: ($d.weather_code[.] | tostring),
            weatherEmoji: emoji($d.weather_code[.]),
            weatherDesc: [{value: desc($d.weather_code[.])}],
            chanceofrain: (( $d.precipitation_probability_max[.] // "" ) | tostring)
          }]
        }
      ]
    }
' 2>/dev/null || echo "{}"
