FROM mcr.microsoft.com/dotnet/runtime:10.0
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends fasm \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["dotnet", "GroundCompiler.dll"]
