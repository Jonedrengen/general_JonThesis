FROM --platform=linux/amd64 ubuntu:22.04 AS base

#get parallel and bash stuff
RUN apt-get update
RUN apt-get install -y bash parallel wget file

#get and install "-O" miniconda locally
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /miniconda.sh
# install with -b (non-interactive) to path /opt/conda and rm installer
RUN bash /miniconda.sh -b -p /opt/miniconda
RUN rm /miniconda.sh

#adding miniconda to path
ENV PATH="/opt/miniconda/bin:$PATH"

#accept terms of service
RUN conda tos accept --channel https://repo.anaconda.com/pkgs/main

##set up conda (have to specify mlst versin, or old version is installed for some reason)
RUN conda create -n mlstfinder
RUN conda install -c conda-forge -c bioconda mlst=2.33.1

#working dir
WORKDIR /src

#copy runner and database from mlst clone containing schemes like ecoli_achtman_4 (for some reasong the dockerfile install does not)
COPY . /src

#make executable
RUN chmod +x mlst_runner.sh

ENTRYPOINT ["./mlst_runner.sh"]

#legacy
#tseeman mlstfinder specific. Perl and CPAN (the Comprehensive Perl Archive Network)
# RUN apt-get install perl 
# RUN apt-get install -y cpanminus
# RUN apt-get install -y ncbi-blast+
# RUN apt-get install -y any2fasta
# #using cpanminus to install Modules
# RUN cpanm JSON

