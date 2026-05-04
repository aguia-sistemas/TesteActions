FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY TesteActions.slnx ./
COPY src/App/App.csproj src/App/
RUN dotnet restore src/App/App.csproj

COPY src/App/ src/App/
RUN dotnet publish src/App/App.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

FROM mcr.microsoft.com/dotnet/runtime-deps:10.0
WORKDIR /app
COPY --from=build /app/publish ./
