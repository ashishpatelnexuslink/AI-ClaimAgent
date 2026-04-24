using System.Text.Json.Serialization;
using ClaimAI.API.Extensions;
using ClaimAI.API.Filters;
using ClaimAI.API.Middleware;
using ClaimAI.Application;
using ClaimAI.Infrastructure;
using ClaimAI.Infrastructure.Data.Seeders;
using Scalar.AspNetCore;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((context, configuration) =>
    configuration.ReadFrom.Configuration(context.Configuration));

// Layer registrations
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddAuthorizationPolicies();

// Controllers with validation filter
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationFilter>();
})
.AddJsonOptions(options =>
{
    // Serialize enums as their string name (e.g. "Motor", "Active") rather than
    // the underlying int. Matches how enums are stored in the DB via
    // .HasConversion<string>() and keeps the API contract human-readable.
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

// OpenAPI with JWT Bearer auth
builder.Services.AddOpenApiWithAuth();

// CORS
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "http://localhost:5173", "http://localhost:3000", "https://claimai.nexuslink.in" };
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials());
});

var app = builder.Build();

// Middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("ClaimAI API");
        options.WithDefaultHttpClient(ScalarTarget.CSharp, ScalarClient.HttpClient);
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles(); // serve wwwroot (profile photos, etc.)
app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

await RoleSeeder.SeedAsync(app.Services);

app.Run();
