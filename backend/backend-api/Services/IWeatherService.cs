using BackendApi.Models;

namespace BackendApi.Services;

public interface IWeatherService
{
    Task<IEnumerable<WeatherForecast>> GetWeatherForecastAsync(int days = 5);
}