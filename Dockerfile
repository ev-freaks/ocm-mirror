FROM mcr.microsoft.com/dotnet/core/sdk:3.1.100

WORKDIR /app

RUN git clone https://github.com/openchargemap/ocm-system \
  && cd ocm-system/API/OCM.Net/OCM.API.Web \
  && dotnet build

WORKDIR /app/ocm-system/API/OCM.Net/OCM.API.Web
ADD files/ .

EXPOSE 5000

ENTRYPOINT ["dotnet", "run"]
CMD ["-c", "Release", "--urls", "http://0.0.0.0:5000"]
