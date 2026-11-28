FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src
COPY src/StatusAPI/StatusAPI.csproj src/StatusAPI/
RUN dotnet restore src/StatusAPI/StatusAPI.csproj
COPY src/StatusAPI/ src/StatusAPI/
RUN dotnet publish src/StatusAPI/StatusAPI.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime
WORKDIR /app
ARG APP_VERSION=local
ENV APP_VERSION=$APP_VERSION

USER app
EXPOSE 8080
COPY --from=build /app/publish .

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/health/live || exit 1

ENTRYPOINT ["dotnet", "StatusAPI.dll"]