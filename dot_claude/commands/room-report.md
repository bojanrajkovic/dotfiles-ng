---
description: Get a detailed status report for a room in Home Assistant
argument-hint: <room-name>
allowed-tools: [Bash, Read]
model: sonnet
---

## Execution Method

**STOP**: Do NOT execute this command directly. You MUST use the Task tool with `subagent_type="general-purpose"` to run this entire workflow. Pass all instructions below to the sub-agent.

If you find yourself running `curl` commands directly in the main conversation, you are doing it wrong. Launch a sub-agent first.

---

# Room Report Command

Generate a comprehensive, beautifully formatted status report for a room in your Home Assistant setup.

## Usage

```
/room-report Main Bedroom
/room-report office
/room-report kitchen
```

## Configuration

**Home Assistant URL**: `http://homeassistant.local:8123`

**Token locations** (check in order):
1. `/Users/brajkovic/Sync/Working/projects/home-assistant/.ha_token`
2. `/Users/brajkovic/Working/projects/home-assistant/.ha_token`
3. `~/.ha_token`

## Instructions

When invoked with room name `$ARGUMENTS`, generate a beautiful terminal UI status report:

### 1. Fetch Room Data

**Get entities in the room:**
```bash
# Get area name (case-insensitive match for $ARGUMENTS)
AREAS=$(curl -s -X POST \
  -H "Authorization: Bearer $(cat /Users/brajkovic/Sync/Working/projects/home-assistant/.ha_token)" \
  -H "Content-Type: application/json" \
  -d '{"template": "{{ areas() | list }}"}' \
  http://homeassistant.local:8123/api/template)

# Get entities for the matched area
ENTITIES=$(curl -s -X POST \
  -H "Authorization: Bearer $(cat /Users/brajkovic/Sync/Working/projects/home-assistant/.ha_token)" \
  -H "Content-Type: application/json" \
  -d "{\"template\": \"{{ area_entities('$AREA') | list }}\"}" \
  http://homeassistant.local:8123/api/template)

# Get current states for those entities
curl -s -H "Authorization: Bearer $(cat /Users/brajkovic/Sync/Working/projects/home-assistant/.ha_token)" \
  http://homeassistant.local:8123/api/states | \
  jq --argjson entities "$ENTITIES" '[.[] | select([.entity_id] | inside($entities))]'
```

**Extract sensor names for display:**

Each state object from `/api/states` contains both the entity ID and human-readable name:
```json
{
  "entity_id": "sensor.office_sensor_temperature",
  "state": "68.5",
  "attributes": {
    "friendly_name": "Office Sensor Temperature",
    "unit_of_measurement": "°F",
    "device_class": "temperature"
  }
}
```

**Use `friendly_name` for all display text:**
```bash
# Example: Extract friendly name and state for a sensor
curl -s -H "Authorization: Bearer $(cat /Users/brajkovic/Sync/Working/projects/home-assistant/.ha_token)" \
  http://homeassistant.local:8123/api/states | \
  jq --argjson entities "$ENTITIES" \
  '[.[] | select([.entity_id] | inside($entities))] |
   .[] | {
     entity_id: .entity_id,
     name: .attributes.friendly_name,
     state: .state,
     unit: .attributes.unit_of_measurement
   }'
```

**Simplify names for compact display:**
- Remove redundant words: "Office Sensor Temperature" → "Office Sensor"
- Remove area prefix if it matches the room: "Office Temperature Sensor" → "Temperature Sensor"
- Use context-appropriate shortening: "Main Bedroom Motion Sensor" → "Motion"

```bash
# Example: Clean up friendly names for display
jq -r '.attributes.friendly_name |
  gsub("(?i)(temperature|humidity|pressure)\\s*sensor"; "") |
  gsub("(?i)^office\\s+"; "") |
  gsub("\\s+"; " ") |
  ltrimstr(" ") |
  rtrimstr(" ")'
```

**CRITICAL: Preserve the semantic meaning of `friendly_name`**

Simplification is OK - verbatim names can be noisy. But don't change the *meaning*.

OK to simplify:
- "Office Sensor Temperature" → "Office Sensor" (removing redundant word in context)
- "Office Humidifier Sonoff S31 Relay" → "Office Humidifier" (removing technical details)
- "Elgato Key Light Air (Left)" → "Key Light Left" (shortening)

NOT OK - changes meaning:
- "Salem House Inside temperature" → "House Average" ❌ (it's a weather station console, not an average)
- "AmbientWeather Console Humidity" → "Indoor Humidity" ❌ (assumes purpose incorrectly)

The key test: Would the user recognize their sensor from your label? "Salem House" is probably their weather station name - keep it identifiable.

Example of WRONG:
```
friendly_name: "Salem House Inside temperature"
→ "House Average: 62.1°F" ❌  (implies aggregation, misrepresents the sensor)
```

Example of CORRECT:
```
friendly_name: "Salem House Inside temperature"
→ "Salem House: 62.1°F" ✓  (simplified but preserves identity)
```

### 2. Fetch Historical Data for Sparklines

For key sensors (temperature, humidity, climate control power), fetch 2 hours of history:

```bash
# Calculate timestamp for 2 hours ago (macOS compatible)
TIMESTAMP=$(date -u -v-2H +"%Y-%m-%dT%H:%M:%S")

# Fetch and sample history for a sensor
curl -s -H "Authorization: Bearer $(cat /Users/brajkovic/Sync/Working/projects/home-assistant/.ha_token)" \
  "http://homeassistant.local:8123/api/history/period/${TIMESTAMP}?filter_entity_id=sensor.office_sensor_temperature" | \
  jq -r 'if . and .[0] then [.[0][] | select(.state | test("^[0-9.]+$")) | .state | tonumber] else [] end' | \
  jq 'if length > 20 then . as $arr | [range(0; length; (length / 20 | floor + 1))] | map($arr[.]) else . end'
```

### 3. Filter and Aggregate Data

**Include these sensors:**
- Temperature, humidity, pressure
- Occupancy, motion, presence
- Lighting (lights, switches)
- Climate control (heater, humidifier, AC, fan)
- Power consumption
- Air quality (CO₂, VOC, PM2.5, formaldehyde)

**Exclude:**
- Network status, connectivity sensors
- Device trackers, update entities
- Button/configuration entities
- Voltage/current (unless part of power summary)
- Temperatures that seem like they're a device temperature rather than a room temperature
- Devices that wouldn't be useful in a room status report (e.g. printers)

**Aggregate multiple sensors:**
- Multiple temperature sensors → calculate and show average
- Multiple humidity sensors → calculate and show average
- Show individual sensor values as sub-items

### 4. Generate Beautiful Terminal UI

Create a visually appealing, information-dense report. **DO NOT attempt perfectly aligned box-drawing layouts** - they never render correctly across terminals.

**Design Guidelines:**

**Use simple, robust visual separators:**
- Section headers: `═══ SECTION NAME ═══════════════════════════════`
- Subsection dividers: `─── Subsection ───`
- Simple horizontal rules: `────────────────────────────────────────────`
- Bullet points and indentation for hierarchy
- NO closed boxes, NO vertical alignment required

**Sparklines for trends:**
- Use Unicode blocks: `▁▂▃▄▅▆▇█`
- Scale values within the dataset (auto-scale to min/max)
- Show 8-20 data points
- Add trend indicators: `↑` (rising), `↓` (falling), `→` (stable)
- Format: `[▁▂▃▄▅▆▇█▇▆▅] ↑` after the value

**Status indicators:**
- `●` for ON/active
- `◯` for OFF/inactive
- `✓` for good/healthy status
- `⚠` for warnings
- `✗` for errors/problems

**Preferred Layout Style:**

Use simple hierarchical text with clear separators. Names are simplified but preserve identity:
```
═══════════════════════════════════════════════════════════════
  OFFICE STATUS REPORT
  Friday, January 10, 2026 · 6:43 PM
═══════════════════════════════════════════════════════════════

─── TEMPERATURE ───────────────────────────────────────────────

Office Sensor: 68.5°F  [▁▂▃▅▆▇▇█] ↑  Cool

  • AmbientWeather Console: 64.6°F (Cool)

─── HUMIDITY & PRESSURE ───────────────────────────────────────

Office Sensor: 41.0%  [▅▃▄▃▄▂▄▄▅▃▇█] →  Comfortable

  • AmbientWeather Console: 39.0% (Dry)

Pressure: 29.92 inHg

─── CLIMATE CONTROL ───────────────────────────────────────────

Humidifier:   ● ON (34.3W)   [█▇▇▆▇▇▇▇▆▆▇] →
Space Heater: ◯ OFF (0W)

Total Power: 34.3W

═══════════════════════════════════════════════════════════════
SUMMARY: Office is vacant and comfortably cool. Humidifier
actively maintaining moisture levels.
═══════════════════════════════════════════════════════════════
```

Notice: Names are simplified ("Office Sensor" not "Office Sensor Temperature") but preserve identity ("AmbientWeather Console" not "House Average").

**Quality labels for readings:**
- CO₂: <400=Excellent, 400-1000=Good, 1000-2000=Fair, >2000=Poor
- Humidity: <30%=Very Dry, 30-40%=Dry, 40-60%=Comfortable, 60-70%=Humid, >70%=Very Humid
- Temperature: <60°F=Cold, 60-68°F=Cool, 68-76°F=Comfortable, 76-80°F=Warm, >80°F=Hot

**Key principles:**
- Use simple horizontal lines (═ and ─) for section separation
- Left-align all content with consistent indentation
- NO vertical pipes or closed boxes that require alignment
- Focus on readability over pixel-perfect aesthetics
- Keep it clean, scannable, and information-dense

### 5. Output Format

**Output ONLY the formatted terminal UI.** No additional commentary, interpretation, or markdown code blocks.

The report should be:
- Clean and easy to scan
- Information-dense but not cluttered
- Show trends at a glance via sparklines
- Professional and readable

**Important:**
- Use the simple horizontal separator style shown in the example above
- DO NOT try to create perfectly aligned boxes with vertical borders
- Left-align everything with consistent 2-space indentation
- Prioritize clarity and information over visual complexity
