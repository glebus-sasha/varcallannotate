Install SDKMAN

```
curl -s https://get.sdkman.io | bash
```
Open a new terminal
```
sdk install java 17.0.10-tem
java -version
```

Install Nextflow
```
curl -s https://get.nextflow.io | bash
chmod +x nextflow
mkdir -p $HOME/.local/bin/
mv nextflow $HOME/.local/bin/
```
Add to $PATH

```
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

update Nextflow
```
nextflow self-update
nextflow info
```

```
grep -qxF 'export NXF_APPTAINER_CACHEDIR="$HOME/.nextflow/apptainer"' ~/.bashrc || echo 'export NXF_APPTAINER_CACHEDIR="$HOME/.nextflow/apptainer"' >> ~/.bashrc && source ~/.bashrc
grep -qxF 'export NXF_SINGULARITY_CACHEDIR="$HOME/.nextflow/singularity"' ~/.bashrc || echo 'export NXF_SINGULARITY_CACHEDIR="$HOME/.nextflow/singularity"' >> ~/.bashrc
source ~/.bashrc

```

Install apptainer
```
# Ensure repositories are up-to-date
sudo apt-get update
# Install debian packages for dependencies
sudo apt-get install -y \
    build-essential \
    libseccomp-dev \
    pkg-config \
    uidmap \
    squashfs-tools \
    fakeroot \
    cryptsetup \
    tzdata \
    dh-apparmor \
    curl wget git
sudo apt-get install -y libsubid-dev
sudo dnf --enablerepo=devel install -y shadow-utils-subid-devel

# Install Go
export GOVERSION=1.23.4 OS=linux ARCH=amd64  # change this as you need

wget -O /tmp/go${GOVERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${GOVERSION}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf /tmp/go${GOVERSION}.${OS}-${ARCH}.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# In order to download and install the latest version of golangci-lint, you can run:
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.59.1

# Add $(go env GOPATH) to the PATH environment variable:
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc

# Clone the repository with git in a location of your choice:
git clone https://github.com/apptainer/apptainer.git
cd apptainer

# Compiling Apptainer
./mconfig
cd $(/bin/pwd)/builddir
make
sudo make install

apptainer --version
```

Launch pipeline in CL

```
cd
mkdir varcallimputblup
cd varcallimputblup
```

Launch varcallannotate test in CL
```
nextflow run -latest glebus-sasha/varcallannotate -profile apptainer,test 
```

Launch varcallannotate in CL
```
touch params.yml
```

```params.yml                                                              
reference: ''
faidx: ''
bwaidx: ''
reads: ''
outdir: ''
reports: true
cpus: '64'
memory: '100'
```

```
nextflow run -latest glebus-sasha/varcallannotate -profile apptainer -params-file params.yml
```

Running varcallannotate in GUI

```
sudo apt install python3-flask
sudo apt install python3-flask-socketio
cd $HOME
git clone https://github.com/glebus-sasha/varcallannotate.git
cd varcallannotate
nano path_config.py
```

```path_config.py
READS_FOLDER    = "$HOME/tmp_reads"
OUTPUT_FOLDER   = "$HOME/tmp_output"
nextflow_path   = "$HOME/varcallannotate"

nextflow_command = ["nextflow", "run",
 "glebus-sasha/varcallannotate", "-profile", "apptainer",
    "--reads", READS_FOLDER,
    "--outdir", OUTPUT_FOLDER,
    "-params-file", "params.yml",
    "--reports"]
```

```
python3 server.py path_config.py
```
