using BackendApi.Services;

namespace BackendApi;

public partial class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        ConfigureServices(builder.Services);
        
        var app = builder.Build();
        ConfigureApp(app);
        
        app.Run();
    }

    public static void ConfigureServices(IServiceCollection services)
    {
        // Add controllers
        services.AddControllers();
        
        // Add API documentation
        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen();
        
        // Register application services
        services.AddScoped<IWeatherService, WeatherService>();
    }

    public static void ConfigureApp(WebApplication app)
    {
        // Configure the HTTP request pipeline.
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        app.UseHttpsRedirection();
        app.UseRouting();
        
        // Map controllers
        app.MapControllers();
    }
}
