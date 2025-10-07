FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["BackendApi.csproj", "./"]
RUN dotnet restore "BackendApi.csproj"
COPY . .
RUN dotnet build "BackendApi.csproj" -c Release -o /app/build
RUN dotnet publish "BackendApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
# Copy HTTPS dev certificate generated in CI/CD
COPY https/aspnetapp.pfx /https/aspnetapp.pfx
EXPOSE 80
EXPOSE 443
# Set environment variables for ASP.NET Core to use HTTPS
ENV ASPNETCORE_Kestrel__Endpoints__Https__Url="https://*:443"
ENV ASPNETCORE_Kestrel__Endpoints__Https__Certificate__Path="/https/aspnetapp.pfx"
ENV ASPNETCORE_Kestrel__Endpoints__Https__Certificate__Password="${CERT_PASSWORD}"
ENTRYPOINT ["dotnet", "BackendApi.dll"]