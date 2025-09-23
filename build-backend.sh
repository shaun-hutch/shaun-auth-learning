#!/bin/bash
set -e

cd backend

dotnet restore
dotnet build --configuration Release --no-restore
cd tests/BackendApi.Tests && dotnet test --no-build --verbosity normal
