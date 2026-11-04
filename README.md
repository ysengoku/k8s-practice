# Kubernetes practice

## Tech Stack

<!-- Use utils/TECH_STACK_LIST.md -->

**Languages:**   

<div>   
  
</div>
<br />

**Frameworks & Libraries:**   

<div>
  
</div>
<br />

**Database:**   

<div>
  
</div>
<br />

**Tools:**   
<div>

</div>
<br />

**Infrastructure:**   
<div>

</div>
<br />

**Development Environment:**   
<div>
</div>

## Getting Started

### Prerequisites

#### `Vagrant`

To install on 42 school session:
```bash
# Download zip from https://developer.hashicorp.com/vagrant/install

mkdir -p ~/.local/bin
cd /tmp
unzip <path to downloaded zip>
mv vagrant ~/.local/bin/

# Check if installed successfully
vagrant --version
```

If `~/.local/bin` is not in `PATH` yet:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Usage

Up VM
```bash
vagrant up
```

Connect to VM
```bash
vagrant ssh
```

Stop VM
```bash
vagrant halt
```
