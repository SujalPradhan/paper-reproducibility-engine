# Not built/tested. Build from the paper folder: docker build -f env/Dockerfile -t hsr-ei .
FROM rocker/r-ver:4.6.1
WORKDIR /work
COPY env/install.R env/install.R
RUN Rscript env/install.R
COPY code/ code/
COPY data/ data/
CMD ["Rscript", "code/reproduce.R"]
