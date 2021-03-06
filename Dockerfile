# see https://hub.docker.com/_/microsoft-dotnet-aspnet/ for available feature tags
ARG DOTNET_TAG=5.0

FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_TAG} AS base
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_TAG} AS build

ARG REPO_URL=https://github.com/openchargemap/ocm-system
ARG REPO_BRANCH=master

WORKDIR /src

RUN git clone "${REPO_URL}" -b "${REPO_BRANCH}" .
# RUN dotnet restore "API/OCM.Net/OCM.API.Worker/OCM.API.Worker.csproj"

WORKDIR /src/API/OCM.Net/OCM.API.Worker
ADD files/ .
RUN dotnet build "OCM.API.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "OCM.API.Worker.csproj" -c Release -o /app/publish

FROM base AS final

WORKDIR /app
EXPOSE 80
EXPOSE 443

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "OCM.API.Worker.dll"]
