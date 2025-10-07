using Microsoft.AspNetCore.Mvc;
using BackendApi.Models;
using BackendApi.Services;

namespace BackendApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WeatherController : ControllerBase
{
    private readonly IWeatherService _weatherService;

    public WeatherController(IWeatherService weatherService)
    {
        _weatherService = weatherService;
    }

    [HttpGet("forecast")]
    public async Task<ActionResult<IEnumerable<WeatherForecast>>> GetWeatherForecast([FromQuery] int days = 5)
    {
        if (days < 1 || days > 30)
        {
            return BadRequest("Days must be between 1 and 30");
        }

        var forecast = await _weatherService.GetWeatherForecastAsync(days);
        return Ok(forecast);
    }
}