# Build stage
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Копіюємо все в контейнер
COPY . .

# Заходимо в каталог з .csproj
WORKDIR /src/SampleWebApiAspNetCore

# Restore dependencies
RUN dotnet restore

# Build and publish release
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app

COPY --from=build /app/publish .

# Запускаємо готову збірку
ENTRYPOINT ["dotnet", "SampleWebApiAspNetCore.dll"]
