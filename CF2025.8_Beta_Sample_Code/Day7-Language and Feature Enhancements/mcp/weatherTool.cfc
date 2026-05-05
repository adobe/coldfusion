component displayname="Weather tools" hint="A comprehensive CFC for weather-related tools" {
    /**
    * Function tool: Get current weather for a city
    * @param city The name of the city
    * @return Struct with success status, city, and weather information
    */
   remote struct function getCurrentWeather(required string city) {

       return {
               "success": true,
               "city": arguments.city,
               "temperature": 87,
               "condition": "Rainy",
               "humidity": 45
           };
   }

   /**
    * Function tool: Get weather forecast for a city
    * @param city The name of the city
    * @param days Number of days to forecast (default 3)
    * @return Struct with success status and forecast data
    */
   remote struct function getForecast(required string city, numeric days=3) {
       var forecast = [];
       var i = 0;
       var conditions = ["Sunny", "Cloudy", "Rainy", "Partly Cloudy"];
       
       for (i = 1; i <= arguments.days; i++) {
           arrayAppend(forecast, {
               "day": i,
               "temperature": randRange(60, 85),
               "condition": conditions[randRange(1, 4)]
           });
       }
       
       return {
               "success": true,
               "city": arguments.city,
               "days": arguments.days,
               "forecast": forecast
           };
   }

   /**
    * Function tool: Get temperature in specified unit
    * @param city The name of the city
    * @param unit Temperature unit (F for Fahrenheit, C for Celsius)
    * @return Struct with success status and temperature
    */
   remote struct function getTemperature(required string city, string unit="F") {
       var tempF = 72;
       var temp = (arguments.unit == "C") ? (tempF - 32) * 5/9 : tempF;
       
       return {
               "success": true,
               "city": arguments.city,
               "temperature": round(temp),
               "unit": arguments.unit
           };
   }
}

