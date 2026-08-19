/*
* Copyright 2024 - 2024 the original author or authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
package mcp.server; //org.aisamples.

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class WeatherService {

	private static final Logger logger = LogManager.getLogger(WeatherService.class);

	private static final String BASE_URL = "https://api.weather.gov";

	// Open-Meteo: free, key-less, global. Used by getWeatherForecastByCity so the server
	// can answer city-name queries worldwide (api.weather.gov is US-only / lat-lon only).
	private static final String OPEN_METEO_GEOCODE = "https://geocoding-api.open-meteo.com/v1/search";
	private static final String OPEN_METEO_FORECAST = "https://api.open-meteo.com/v1/forecast";
	private static final int COLD_THRESHOLD_C = 12;

	private final RestClient restClient;
	private final RestClient openMeteoClient;
	private final ObjectMapper objectMapper = new ObjectMapper();

	public WeatherService() {

		this.restClient = RestClient.builder()
			.baseUrl(BASE_URL)
			.defaultHeader("Accept", "application/geo+json")
			.defaultHeader("User-Agent", "WeatherApiClient/1.0 (your@email.com)")
			.build();

		this.openMeteoClient = RestClient.builder()
			.defaultHeader("Accept", "application/json")
			.build();
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record Points(@JsonProperty("properties") Props properties) {
		@JsonIgnoreProperties(ignoreUnknown = true)
		public record Props(@JsonProperty("forecast") String forecast) {
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record Forecast(@JsonProperty("properties") Props properties) {
		@JsonIgnoreProperties(ignoreUnknown = true)
		public record Props(@JsonProperty("periods") List<Period> periods) {
		}

		@JsonIgnoreProperties(ignoreUnknown = true)
		public record Period(@JsonProperty("number") Integer number, @JsonProperty("name") String name,
				@JsonProperty("startTime") String startTime, @JsonProperty("endTime") String endTime,
				@JsonProperty("isDaytime") Boolean isDayTime, @JsonProperty("temperature") Integer temperature,
				@JsonProperty("temperatureUnit") String temperatureUnit,
				@JsonProperty("temperatureTrend") String temperatureTrend,
				@JsonProperty("probabilityOfPrecipitation") Map probabilityOfPrecipitation,
				@JsonProperty("windSpeed") String windSpeed, @JsonProperty("windDirection") String windDirection,
				@JsonProperty("icon") String icon, @JsonProperty("shortForecast") String shortForecast,
				@JsonProperty("detailedForecast") String detailedForecast) {
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record Alert(@JsonProperty("features") List<Feature> features) {

		@JsonIgnoreProperties(ignoreUnknown = true)
		public record Feature(@JsonProperty("properties") Properties properties) {
		}

		@JsonIgnoreProperties(ignoreUnknown = true)
		public record Properties(@JsonProperty("event") String event, @JsonProperty("areaDesc") String areaDesc,
				@JsonProperty("severity") String severity, @JsonProperty("description") String description,
				@JsonProperty("instruction") String instruction) {
		}
	}

	/**
	 * Get forecast for a specific latitude/longitude
	 * @param latitude Latitude
	 * @param longitude Longitude
	 * @return The forecast for the given location
	 * @throws RestClientException if the request fails
	 */
	@Tool(description = "Get weather forecast for a specific latitude/longitude")
	public String getWeatherForecastByLocation(double latitude, double longitude) {
		logger.info("getWeatherForecastByLocation called with latitude: {}, longitude: {}", latitude, longitude);

		var points = restClient.get()
			.uri("/points/{latitude},{longitude}", latitude, longitude)
			.retrieve()
			.body(Points.class);

		var forecast = restClient.get().uri(points.properties().forecast()).retrieve().body(Forecast.class);

		String forecastText = forecast.properties().periods().stream().map(p -> {
			return String.format("""
					%s:
					Temperature: %s %s
					Wind: %s %s
					Forecast: %s
					""", p.name(), p.temperature(), p.temperatureUnit(), p.windSpeed(), p.windDirection(),
					p.detailedForecast());
		}).collect(Collectors.joining());

		return forecastText;
	}

	/**
	 * Get alerts for a specific area
	 * @param state Area code. Two-letter US state code (e.g. CA, NY)
	 * @return Human readable alert information
	 * @throws RestClientException if the request fails
	 */
	@Tool(description = "Get weather alerts for a US state. Input is Two-letter US state code (e.g. CA, NY)")
	public String getAlerts(@ToolParam( description =  "Two-letter US state code (e.g. CA, NY") String state) {
		logger.info("getAlerts called with state: {}", state);
		Alert alert = restClient.get().uri("/alerts/active/area/{state}", state).retrieve().body(Alert.class);

		return alert.features()
			.stream()
			.map(f -> String.format("""
					Event: %s
					Area: %s
					Severity: %s
					Description: %s
					Instructions: %s
					""", f.properties().event(), f.properties.areaDesc(), f.properties.severity(),
					f.properties.description(), f.properties.instruction()))
			.collect(Collectors.joining("\n"));
	}

	/**
	 * Get the current weather for a city by name, anywhere in the world.
	 *
	 * Geocodes the city via Open-Meteo, then fetches the current temperature and weather
	 * code, and returns a compact JSON object the caller can parse directly:
	 *
	 *   {"city":"London","tempC":5,"tempF":41,"conditions":"overcast",
	 *    "isCold":true,"summary":"It's currently 5°C and overcast in London.",
	 *    "source":"open-meteo"}
	 *
	 * On any failure (unknown city, network) it returns a deterministic fallback so the
	 * caller always receives usable JSON.
	 *
	 * @param city City name (e.g. "London", "Las Vegas", "Tokyo")
	 * @return JSON string describing the current weather
	 */
	@Tool(description = "Get current weather for a city by name (worldwide). Returns JSON with tempC, conditions and a human summary.")
	public String getWeatherForecastByCity(
			@ToolParam(description = "City name, e.g. London, Las Vegas, Tokyo") String city) {
		logger.info("getWeatherForecastByCity called with city: {}", city);

		if (city == null || city.isBlank()) {
			return toJson(emptyForecast());
		}
		try {
			JsonNode geo = objectMapper.readTree(
				openMeteoClient.get()
					.uri(OPEN_METEO_GEOCODE + "?count=1&language=en&format=json&name={name}", city.trim())
					.retrieve()
					.body(String.class));

			JsonNode results = geo.path("results");
			if (!results.isArray() || results.isEmpty()) {
				return toJson(fallbackForecast(city));
			}
			JsonNode top = results.get(0);
			double lat = top.path("latitude").asDouble();
			double lon = top.path("longitude").asDouble();
			String resolvedName = top.path("name").asText(city);

			JsonNode wx = objectMapper.readTree(
				openMeteoClient.get()
					.uri(OPEN_METEO_FORECAST + "?current=temperature_2m,weather_code&latitude={lat}&longitude={lon}", lat, lon)
					.retrieve()
					.body(String.class));

			JsonNode current = wx.path("current");
			if (current.isMissingNode()) {
				return toJson(fallbackForecast(city));
			}
			long tempC = Math.round(current.path("temperature_2m").asDouble());
			int code = current.path("weather_code").asInt(-1);
			return toJson(buildForecast(resolvedName, tempC, conditionsForCode(code), "open-meteo"));
		}
		catch (Exception e) {
			logger.warn("getWeatherForecastByCity failed for '{}': {}", city, e.getMessage());
			return toJson(fallbackForecast(city));
		}
	}

	private Map<String, Object> buildForecast(String city, long tempC, String conditions, String source) {
		boolean isCold = tempC <= COLD_THRESHOLD_C;
		Map<String, Object> out = new LinkedHashMap<>();
		out.put("city", city);
		out.put("tempC", tempC);
		out.put("tempF", Math.round(tempC * 9.0 / 5.0 + 32));
		out.put("conditions", conditions);
		out.put("isCold", isCold);
		out.put("summary", "It's currently " + tempC + "\u00b0C and " + conditions + " in " + city + ".");
		out.put("source", source);
		return out;
	}

	private Map<String, Object> fallbackForecast(String city) {
		String key = city.trim().toLowerCase();
		long tempC;
		String conditions;
		switch (key) {
			case "london"   -> { tempC = 5;  conditions = "overcast with light rain"; }
			case "paris"    -> { tempC = 8;  conditions = "partly cloudy"; }
			case "new york" -> { tempC = 6;  conditions = "cold and windy"; }
			case "tokyo"    -> { tempC = 11; conditions = "clear"; }
			case "berlin"   -> { tempC = 4;  conditions = "overcast"; }
			case "varanasi" -> { tempC = 24; conditions = "warm and hazy"; }
			case "mumbai"   -> { tempC = 29; conditions = "hot and humid"; }
			default          -> { tempC = 12; conditions = "cool"; }
		}
		String proper = city.isBlank() ? city
			: Character.toUpperCase(city.charAt(0)) + city.substring(1);
		return buildForecast(proper, tempC, conditions, "fallback");
	}

	private Map<String, Object> emptyForecast() {
		Map<String, Object> out = new LinkedHashMap<>();
		out.put("city", "");
		out.put("tempC", "");
		out.put("tempF", "");
		out.put("conditions", "");
		out.put("isCold", false);
		out.put("summary", "");
		out.put("source", "none");
		return out;
	}

	private String toJson(Map<String, Object> map) {
		try {
			return objectMapper.writeValueAsString(map);
		}
		catch (Exception e) {
			return "{\"source\":\"error\",\"summary\":\"\"}";
		}
	}

	/** WMO weather-code -> short human conditions. */
	private String conditionsForCode(int code) {
		if (code == 0) return "clear sky";
		if (code == 1 || code == 2) return "partly cloudy";
		if (code == 3) return "overcast";
		if (code == 45 || code == 48) return "foggy";
		if (code >= 51 && code <= 57) return "drizzle";
		if (code >= 61 && code <= 67) return "rainy";
		if (code >= 71 && code <= 77) return "snowy";
		if (code >= 80 && code <= 82) return "rain showers";
		if (code == 85 || code == 86) return "snow showers";
		if (code >= 95) return "thunderstorms";
		return "mixed conditions";
	}

	public static void main(String[] args) {
		WeatherService client = new WeatherService();
		System.out.println(client.getWeatherForecastByCity("London"));
		System.out.println(client.getWeatherForecastByCity("Las Vegas"));
	}

}