# go to backend folder (optional)
cd backend/backend-api

dotnet restore BackendApi.csproj

# build API (Release, no restore since restored)
dotnet build BackendApi.csproj --configuration Release --no-restore

# build tests (Release, restore)
cd ../tests && dotnet test BackendApi.Tests.csproj -c Release