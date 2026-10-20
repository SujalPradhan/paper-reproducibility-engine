FROM rocker/r-ver:4.6.1
COPY env/install.R /tmp/install.R
RUN Rscript /tmp/install.R
WORKDIR /work
COPY . /work
CMD ["Rscript", "code/reproduce.R"]
