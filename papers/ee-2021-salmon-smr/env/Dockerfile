# Not built. Approximates the reproduction environment.
FROM rocker/r-ver:4.6.1
RUN apt-get update && apt-get install -y --no-install-recommends libxml2-dev libcurl4-openssl-dev libssl-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev gfortran && rm -rf /var/lib/apt/lists/*
WORKDIR /paper
COPY env/install.R env/install.R
RUN Rscript env/install.R
COPY . /paper
CMD ["Rscript", "code/reproduce.R"]
