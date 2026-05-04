Short instructions to build and run the MLSTFinder container.

# FIRST!
install and open docker desktop: https://docs.docker.com/desktop/ 

### Build 
```sh
cd ~/mlstfinder
docker build -t mlstfinder .
```

### Run
Mount two volumes: one for input, one for output.
```sh
docker run --rm -v /full/path/to/ecoli_assemblies:/src/input -v /full/path/to/output_folder:/src/out mlstfinder -i /src/input -o /src/out
```
For help
```sh
docker run --rm mlstfinder -h
```

### Run with config [NOT IMPLEMENTED]
Mount two volumes: one for input, one for output.
```sh
docker run --rm -v /full/path/to/ecoli_assemblies:/src/input -v /full/path/to/output_folder:/src/out -v /full/path/to/config:/src/out mlstfinder -i /src/input -o /src/out -c /src/conf
```

### Input
- Place your FASTA files in the input folder you mount to `/src/input`.

### Output
- Results will be written to the output folder you mount to `/src/out`.

### Notes
- The container deletes itself after running (`--rm` flag).
- Adjust paths as needed for your system.

### Troubleshooting
- Ensure input/output paths are absolute and exist on your system.
