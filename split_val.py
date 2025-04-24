import os
import shutil

def process_val_file(input_file):
    OUTPUT_DIR = 'src'
    # Clear build directory if it exists
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    
    # Create build directory
    os.makedirs(OUTPUT_DIR)
    
    current_file = None
    current_name = None
    skip_first = True
    
    with open(input_file, 'r') as f:
        for line in f:
            # Skip first record
            if skip_first:
                skip_first = False
                continue
                
            # Check for header
            if line.startswith('*HEADER'):
                print(f"{line=}")
                # Parse header line
                parts = line.strip().split(',')
                if len(parts) >= 5 and parts[3] == 'SUBPRG':
                    filetype = parts[1]
                    name = parts[4].split()[0]  # Take only the first part before any spaces
                elif len(parts) >= 3:
                    filetype = parts[1]
                    name = parts[2].split()[0]  # Take only the first part before any spaces
                print(f"{filetype=}, {name=}")
                # Determine file extension
                if filetype == 'COBOL':
                    ext = '.CBL'
                elif filetype == 'CLBRY':
                    ext = '.CPY'
                elif filetype.startswith('DATA'):
                    ext = '.DAT'
                else:
                    assert False, f"Unknown file type: {filetype}"
                filename = f"{OUTPUT_DIR}/{name}{ext}"
                print(f"{filename=}")
                current_file = open(filename, 'w')
                current_name = name
            # Check for end of file marker
            elif line.startswith(f'*END-OF,{current_name}' if current_name else '*END-OF'):
                if current_file:
                    current_file.close()
                    current_file = None
                    current_name = None
            
            # Write content to current file if one is open
            elif current_file:
                current_file.write(line)

    # Close any open file
    if current_file:
        current_file.close()

# Run the script
if __name__ == '__main__':
    process_val_file('newcob.val')

    file_count = len([name for name in os.listdir('src') if os.path.isfile(os.path.join('src', name))])
    print(f"Number of files in src: {file_count}")
