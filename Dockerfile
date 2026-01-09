# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/DotNetApp/DotNetApp.csproj", "DotNetApp/"]
RUN dotnet restore "DotNetApp/DotNetApp.csproj"
COPY src/DotNetApp/. DotNetApp/
WORKDIR "/src/DotNetApp"
RUN dotnet build "DotNetApp.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "DotNetApp.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=publish /app/publish .
EXPOSE 80
ENTRYPOINT ["dotnet", "DotNetApp.dll"]
