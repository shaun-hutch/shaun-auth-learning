#!/bin/bash
set -e

cd "$(dirname "$0")"
cd backend

dotnet restore BackendSolution.sln
dotnet build BackendSolution.sln --configuration Release --no-restore
dotnet test tests/BackendApi.Tests/BackendApi.Tests.csproj --no-build --verbosity normal
