# Nano Bots 💎 🤖

An implementation of the [Nano Bots](https://spec.nbots.io) specification with support for [Anthropic Claude](https://www.anthropic.com/claude), [Cohere Command](https://cohere.com), [Google Gemini](https://deepmind.google/technologies/gemini), [Maritaca AI Sabiá](https://www.maritaca.ai), [Mistral AI](https://mistral.ai), [Ollama](https://ollama.ai), [OpenAI ChatGPT](https://openai.com/chatgpt), and others, with support for calling tools (functions).

![Ruby Nano Bots](https://raw.githubusercontent.com/icebaker/assets/main/nano-bots/ruby-nano-bots-canvas.png)

https://user-images.githubusercontent.com/113217272/238141567-c58a240c-7b67-4b3b-864a-0f49bbf6e22f.mp4

## TL;DR and Quick Start

```sh
gem install nano-bots -v 3.4.0
```

```bash
nb - - eval "hello"
# => Hello! How may I assist you today?
```

```bash
nb - - repl
```

```text
🤖> Hi, how are you doing?

As an AI language model, I do not experience emotions but I am functioning
well. How can I assist you?

🤖> |
```

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: openai
  credentials:
    access-token: ENV/OPENAI_API_KEY
  settings:
    user: ENV/NANO_BOTS_END_USER
    model: gpt-4o
```

```bash
nb gpt.yml - eval "hi"
# => Hello! How can I assist you today?
```

```ruby
gem 'nano-bots', '~> 3.4.0'
```

```ruby
require 'nano-bots'

bot = NanoBot.new(cartridge: 'gpt.yml')

bot.eval('Hi!') do |content, fragment, finished, meta|
  print fragment unless fragment.nil?
end

# => Hello! How can I assist you today?
```

- [TL;DR and Quick Start](#tldr-and-quick-start)
- [Usage](#usage)
  - [Command Line](#command-line)
  - [Debugging](#debugging)
  - [Library](#library)
- [Setup](#setup)
  - [Anthropic Claude](#anthropic-claude)
  - [Cohere Command](#cohere-command)
  - [Maritaca AI MariTalk](#maritaca-ai-maritalk)
  - [Mistral AI](#mistral-ai)
  - [Ollama](#ollama)
  - [OpenAI ChatGPT](#openai-chatgpt)
  - [Google Gemini](#google-gemini)
    - [Option 1: API Key (Generative Language API)](#option-1-api-key-generative-language-api)
    - [Option 2: Service Account Credentials File (Vertex AI API)](#option-2-service-account-credentials-file-vertex-ai-api)
    - [Option 3: Application Default Credentials (Vertex AI API)](#option-3-application-default-credentials-vertex-ai-api)
    - [Custom Project ID](#custom-project-id)
- [Cartridges](#cartridges)
  - [Tools (Functions)](#tools-functions)
      - [Experimental Clojure Support](#experimental-clojure-support)
  - [Marketplace](#marketplace)
- [Security and Privacy](#security-and-privacy)
  - [Cryptography](#cryptography)
  - [End-user IDs](#end-user-ids)
  - [Decrypting](#decrypting)
- [Supported Providers](#supported-providers)
- [Docker](#docker)
  - [Anthropic Claude Container](#anthropic-claude-container)
  - [Cohere Command Container](#cohere-command-container)
  - [Maritaca AI MariTalk Container](#maritaca-ai-maritalk-container)
  - [Mistral AI Container](#mistral-ai-container)
  - [Ollama Container](#ollama-container)
  - [OpenAI ChatGPT Container](#openai-chatgpt-container)
  - [Google Gemini Container](#google-gemini-container)
    - [Option 1: API Key (Generative Language API) Config](#option-1-api-key-generative-language-api-config)
    - [Option 2: Service Account Credentials File (Vertex AI API) Config](#option-2-service-account-credentials-file-vertex-ai-api-config)
    - [Option 3: Application Default Credentials (Vertex AI API) Config](#option-3-application-default-credentials-vertex-ai-api-config)
    - [Custom Project ID Config](#custom-project-id-config)
  - [Running the Container](#running-the-container)
- [Development](#development)
  - [Publish to RubyGems](#publish-to-rubygems)

## Usage

### Command Line

After installing the gem, the `nb` binary command will be available for your project or system.

Examples of usage:

```bash
nb - - eval "hello"
# => Hello! How may I assist you today?

nb to-en-us-translator.yml - eval "Salut, comment ça va?"
# => Hello, how are you doing?

nb midjourney.yml - eval "happy cyberpunk robot"
# => A cheerful and fun-loving robot is dancing wildly amidst a
#    futuristic and lively cityscape. Holographic advertisements
#    and vibrant neon colors can be seen in the background.

nb lisp.yml - eval "(+ 1 2)"
# => 3

cat article.txt |
  nb to-en-us-translator.yml - eval |
  nb summarizer.yml - eval
# -> LLM stands for Large Language Model, which refers to an
#    artificial intelligence algorithm capable of processing
#    and understanding vast amounts of natural language data,
#    allowing it to generate human-like responses and perform
#    a range of language-related tasks.
```

```bash
nb - - repl

nb assistant.yml - repl
```

```text
🤖> Hi, how are you doing?

As an AI language model, I do not experience emotions but I am functioning
well. How can I assist you?

🤖> |
```

You can exit the REPL by typing `exit`.

All of the commands above are stateless. If you want to preserve the history of your interactions, replace the `-` with a state key:

```bash
nb assistant.yml your-user eval "Salut, comment ça va?"
nb assistant.yml your-user repl

nb assistant.yml 6ea6c43c42a1c076b1e3c36fa349ac2c eval "Salut, comment ça va?"
nb assistant.yml 6ea6c43c42a1c076b1e3c36fa349ac2c repl
```

You can use a simple key, such as your username, or a randomly generated one:

```ruby
require 'securerandom'

SecureRandom.hex # => 6ea6c43c42a1c076b1e3c36fa349ac2c
```

### Debugging

```sh
nb - - cartridge
nb cartridge.yml - cartridge

nb - STATE-KEY state
nb cartridge.yml STATE-KEY state
```

### Library

To use it as a library:

```ruby
require 'nano-bots/cli' # Equivalent to the `nb` command.
```

```ruby
require 'nano-bots'

NanoBot.cli # Equivalent to the `nb` command.

NanoBot.repl(cartridge: 'cartridge.yml') # Starts a new REPL.

bot = NanoBot.new(cartridge: 'cartridge.yml')

bot = NanoBot.new(
  cartridge: YAML.safe_load(File.read('cartridge.yml'), permitted_classes: [Symbol])
)

bot = NanoBot.new(
  cartridge: { ... } # Parsed Cartridge Hash
)

bot.eval('Hello')

bot.eval('Hello', as: 'eval')
bot.eval('Hello', as: 'repl')

# When stream is enabled and available:
bot.eval('Hi!') do |content, fragment, finished, meta|
  print fragment unless fragment.nil?
end

bot.repl # Starts a new REPL.

NanoBot.repl(cartridge: 'cartridge.yml', state: '6ea6c43c42a1c076b1e3c36fa349ac2c')

bot = NanoBot.new(cartridge: 'cartridge.yml', state: '6ea6c43c42a1c076b1e3c36fa349ac2c')

bot.prompt # => "🤖\u001b[34m> \u001b[0m"

bot.boot

bot.boot(as: 'eval')
bot.boot(as: 'repl')

bot.boot do |content, fragment, finished, meta|
  print fragment unless fragment.nil?
end
```

## Setup

To install the CLI on your system:

```sh
gem install nano-bots -v 3.4.0
```

To use it in a Ruby project as a library, add to your `Gemfile`:

```ruby
gem 'nano-bots', '~> 3.4.0'
```

```sh
bundle install
```

For credentials and configurations, relevant environment variables can be set in your `.bashrc`, `.zshrc`, or equivalent files, as well as in your Docker Container or System Environment. Example:

```sh
export NANO_BOTS_ENCRYPTION_PASSWORD=UNSAFE
export NANO_BOTS_END_USER=your-user

# export NANO_BOTS_STATE_PATH=/home/user/.local/state/nano-bots
# export NANO_BOTS_CARTRIDGES_PATH=/home/user/.local/share/nano-bots/cartridges
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
NANO_BOTS_ENCRYPTION_PASSWORD=UNSAFE
NANO_BOTS_END_USER=your-user

# NANO_BOTS_STATE_PATH=/home/user/.local/state/nano-bots
# NANO_BOTS_CARTRIDGES_PATH=/home/user/.local/share/nano-bots/cartridges
```

### Anthropic Claude

You can obtain your credentials on the [Anthropic Console](https://console.anthropic.com).

```sh
export ANTHROPIC_API_KEY=your-api-key
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
ANTHROPIC_API_KEY=your-api-key
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: anthropic
  credentials:
    api-key: ENV/ANTHROPIC_API_KEY
  settings:
    model: claude-3-5-sonnet-20240620
    max_tokens: 4096
```

Read the [full specification](https://spec.nbots.io/#/README?id=anthropic-claude) for Anthropic Claude.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

### Cohere Command

You can obtain your credentials on the [Cohere Platform](https://dashboard.cohere.com).

```sh
export COHERE_API_KEY=your-api-key
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
COHERE_API_KEY=your-api-key
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: cohere
  credentials:
    api-key: ENV/COHERE_API_KEY
  settings:
    model: command
```

Read the [full specification](https://spec.nbots.io/#/README?id=cohere-command) for Cohere Command.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

### Maritaca AI MariTalk

You can obtain your API key at [MariTalk](https://chat.maritaca.ai).

Enclose credentials in single quotes when using environment variables to prevent issues with the $ character in the API key:

```sh
export MARITACA_API_KEY='123...$a12...'
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
MARITACA_API_KEY='123...$a12...'
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: maritaca
  credentials:
    api-key: ENV/MARITACA_API_KEY
  settings:
    model: sabia-2-medium
```

Read the [full specification](https://spec.nbots.io/#/README?id=mistral-ai) for Mistral AI.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

### Mistral AI

You can obtain your credentials on the [Mistral Platform](https://console.mistral.ai).

```sh
export MISTRAL_API_KEY=your-api-key
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
MISTRAL_API_KEY=your-api-key
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: mistral
  credentials:
    api-key: ENV/MISTRAL_API_KEY
  settings:
    model: mistral-medium-latest
```

Read the [full specification](https://spec.nbots.io/#/README?id=mistral-ai) for Mistral AI.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

### Ollama

To install and set up, follow the instructions on the [Ollama](https://ollama.ai) website.

```sh
export OLLAMA_API_ADDRESS=http://localhost:11434
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
OLLAMA_API_ADDRESS=http://localhost:11434
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: ollama
  credentials:
    address: ENV/OLLAMA_API_ADDRESS
  settings:
    model: llama3
```

Read the [full specification](https://spec.nbots.io/#/README?id=ollama) for Ollama.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

### OpenAI ChatGPT

You can obtain your credentials on the [OpenAI Platform](https://platform.openai.com).

```sh
export OPENAI_API_KEY=your-access-token
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
OPENAI_API_KEY=your-access-token
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: openai
  credentials:
    access-token: ENV/OPENAI_API_KEY
  settings:
    user: ENV/NANO_BOTS_END_USER
    model: gpt-4o
```

Read the [full specification](https://spec.nbots.io/#/README?id=openai-chatgpt) for OpenAI ChatGPT.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

### Google Gemini

Click [here](https://github.com/gbaptista/gemini-ai#credentials) to learn how to obtain your credentials.

#### Option 1: API Key (Generative Language API)

```sh
export GOOGLE_API_KEY=your-api-key
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
GOOGLE_API_KEY=your-api-key
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: google
  credentials:
    service: generative-language-api
    api-key: ENV/GOOGLE_API_KEY
  options:
    model: gemini-pro
```

Read the [full specification](https://spec.nbots.io/#/README?id=google-gemini) for Google Gemini.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

#### Option 2: Service Account Credentials File (Vertex AI API)

```sh
export GOOGLE_CREDENTIALS_FILE_PATH=google-credentials.json
export GOOGLE_REGION=us-east4
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
GOOGLE_CREDENTIALS_FILE_PATH=google-credentials.json
GOOGLE_REGION=us-east4
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: google
  credentials:
    service: vertex-ai-api
    file-path: ENV/GOOGLE_CREDENTIALS_FILE_PATH
    region: ENV/GOOGLE_REGION
  options:
    model: gemini-pro
```

Read the [full specification](https://spec.nbots.io/#/README?id=google-gemini) for Google Gemini.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

#### Option 3: Application Default Credentials (Vertex AI API)

```sh
export GOOGLE_REGION=us-east4
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
GOOGLE_REGION=us-east4
```

Create a `cartridge.yml` file:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: google
  credentials:
    service: vertex-ai-api
    region: ENV/GOOGLE_REGION
  options:
    model: gemini-pro
```

Read the [full specification](https://spec.nbots.io/#/README?id=google-gemini) for Google Gemini.

```bash
nb cartridge.yml - eval "Hello"

nb cartridge.yml - repl
```

```ruby
bot = NanoBot.new(cartridge: 'cartridge.yml')

puts bot.eval('Hello')
```

#### Custom Project ID

If you need to manually set a Google Project ID:

```sh
export GOOGLE_PROJECT_ID=your-project-id
```

Alternatively, if your current directory has a `.env` file with the environment variables, they will be automatically loaded:

```sh
GOOGLE_PROJECT_ID=your-project-id
```

Add to your `cartridge.yml` file:

```yaml
---
provider:
  id: google
  credentials:
    project-id: ENV/GOOGLE_PROJECT_ID
```

## Cartridges

Check the Nano Bots specification to learn more about [how to build cartridges](https://spec.nbots.io/#/README?id=cartridges).

Try the [Nano Bots Clinic (Live Editor)](https://clinic.nbots.io) to learn about creating Cartridges.

Here's what a Nano Bot Cartridge looks like:

```yaml
---
meta:
  symbol: 🤖
  name: Nano Bot Name
  author: Your Name
  version: 1.0.0
  license: CC0-1.0
  description: A helpful assistant.

behaviors:
  interaction:
    directive: You are a helpful assistant.

provider:
  id: openai
  credentials:
    access-token: ENV/OPENAI_API_KEY
  settings:
    user: ENV/NANO_BOTS_END_USER
    model: gpt-4o
```

### Tools (Functions)

Nano Bots can also be powered by _Tools_ (Functions):

```yaml
---
tools:
  - name: random-number
    description: Generates a random number between 1 and 100.
    fennel: |
      (math.random 1 100)
```

```
🤖> please generate a random number

random-number {} [yN] y

random-number {}
59

The randomly generated number is 59.

🤖> |
```
To successfully use Tools (Functions), you need to specify a provider and a model that supports them. As of the writing of this README, the provider that supports them is [OpenAI](https://platform.openai.com/docs/models), with models `gpt-3.5-turbo-1106` and `gpt-4o`, and [Google](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#supported_models), with the `vertex-ai-api` service and the model `gemini-pro`. Other providers do not yet have support.

Check the [Nano Bots specification](https://spec.nbots.io/#/README?id=tools-functions-2) to learn more about Tools (Functions).

#### Experimental Clojure Support

We are exploring the use of [Clojure](https://clojure.org) through [Babashka](https://babashka.org), powered by [GraalVM](https://www.graalvm.org).

The experimental support for Clojure would be similar to Lua and Fennel, using the `clojure:` key:

```yaml
---
clojure: |
  (-> (java.time.ZonedDateTime/now)
      (.format (java.time.format.DateTimeFormatter/ofPattern "yyyy-MM-dd HH:mm"))
      (clojure.string/trimr))
```

Unlike Lua and Fennel, Clojure support is not _embedded_ in this implementation. It relies on having the Babashka binary (`bb`) available in your environment where the Nano Bot is running.

Here's [how to install Babashka](https://github.com/babashka/babashka#quickstart):

```sh
curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | sudo bash
```

This is a quick check to ensure that it is available and working:
```sh
bb -e '{:hello "world"}'
# => {:hello "world"}
```

We don't have sandbox support for Clojure; this means that you need to disable it to be able to run Clojure code, which you do at your own risk:

```yaml
---
safety:
  functions:
    sandboxed: false
```

### Marketplace

You can explore the Nano Bots [Marketplace](https://nbots.io) to discover new Cartridges that can help you.

## Security and Privacy

Each provider will have its own security and privacy policies (e.g. [OpenAI Policy](https://openai.com/policies/api-data-usage-policies)), so you must consult them to understand their implications.

### Cryptography

By default, all states stored in your local disk are encrypted.

To ensure that the encryption is secure, you need to define a password through the `NANO_BOTS_ENCRYPTION_PASSWORD` environment variable. Otherwise, although the content will be encrypted, anyone would be able to decrypt it without a password.

It's important to note that the content shared with providers, despite being transmitted over secure connections (e.g., [HTTPS](https://en.wikipedia.org/wiki/HTTPS)), will be readable by the provider. This is because providers need to operate on the data, which would not be possible if the content was encrypted beyond HTTPS. So, the data stored locally on your system is encrypted, which does not mean that what you share with providers will not be readable by them.

To ensure that your encryption and password are configured properly, you can run the following command:
```sh
nb security
```

Which should return:
```text
✅ Encryption is enabled and properly working.
     This means that your data is stored in an encrypted format on your disk.

✅ A password is being used for the encrypted content.
     This means that only those who possess the password can decrypt your data.
```

Alternatively, you can check it at runtime with:
```ruby
require 'nano-bots'

NanoBot.security.check
# => { encryption: true, password: true }
```

### End-user IDs

A common strategy for deploying Nano Bots to multiple users through APIs or automations is to assign a unique [end-user ID](https://platform.openai.com/docs/guides/safety-best-practices/end-user-ids) for each user. This can be useful if any of your users violate the provider's policy due to abusive behavior. By providing the end-user ID, you can unravel that even though the activity originated from your API Key, the actions taken were not your own.

You can define custom end-user identifiers in the following way:

```ruby
NanoBot.new(environment: { NANO_BOTS_END_USER: 'custom-user-a' })
NanoBot.new(environment: { NANO_BOTS_END_USER: 'custom-user-b' })
```

Consider that you have the following end-user identifier in your environment:
```sh
NANO_BOTS_END_USER=your-name
```

Or a configuration in your Cartridge:
```yml
---
provider:
  id: openai
  settings:
    user: your-name
```

The requests will be performed as follows:

```ruby
NanoBot.new(cartridge: '-')
# { user: 'your-name' }

NanoBot.new(cartridge: '-', environment: { NANO_BOTS_END_USER: 'custom-user-a' })
# { user: 'custom-user-a' }

NanoBot.new(cartridge: '-', environment: { NANO_BOTS_END_USER: 'custom-user-b' })
# { user: 'custom-user-b' }
```

Actually, to enhance privacy, neither your user nor your users' identifiers will be shared in this way. Instead, they will be encrypted before being shared with the provider:

```ruby
'your-name'
# _O7OjYUESagb46YSeUeSfSMzoO1Yg0BZqpsAkPg4j62SeNYlgwq3kn51Ob2wmIehoA==

'custom-user-a'
# _O7OjYUESagb46YSeUeSfSMzoO1Yg0BZJgIXHCBHyADW-rn4IQr-s2RvP7vym8u5tnzYMIs=

'custom-user-b'
# _O7OjYUESagb46YSeUeSfSMzoO1Yg0BZkjUwCcsh9sVppKvYMhd2qGRvP7vym8u5tnzYMIg=
```

In this manner, you possess identifiers if required, however, their actual content can only be decrypted by you via your secure password (`NANO_BOTS_ENCRYPTION_PASSWORD`).

### Decrypting

To decrypt your encrypted data, once you have properly configured your password, you can simply run:

```ruby
require 'nano-bots'

NanoBot.security.decrypt('_O7OjYUESagb46YSeUeSfSMzoO1Yg0BZqpsAkPg4j62SeNYlgwq3kn51Ob2wmIehoA==')
# your-name

NanoBot.security.decrypt('_O7OjYUESagb46YSeUeSfSMzoO1Yg0BZJgIXHCBHyADW-rn4IQr-s2RvP7vym8u5tnzYMIs=')
# custom-user-a

NanoBot.security.decrypt('_O7OjYUESagb46YSeUeSfSMzoO1Yg0BZkjUwCcsh9sVppKvYMhd2qGRvP7vym8u5tnzYMIg=')
# custom-user-b
```

If you lose your password, you lose your data. It is not possible to recover it at all. For real.

## Supported Providers

- [x] [Anthropic Claude](https://www.anthropic.com)
- [x] [Cohere Command](https://cohere.com)
- [x] [Google Gemini](https://deepmind.google/technologies/gemini)
- [x] [Maritaca AI MariTalk](https://www.maritaca.ai)
- [x] [Mistral AI](https://mistral.ai)
- [x] [Ollama](https://ollama.ai)
  - [x] [01.AI Yi](https://01.ai)
  - [x] [LMSYS Vicuna](https://github.com/lm-sys/FastChat)
  - [x] [Meta Llama](https://ai.meta.com/llama/)
  - [x] [WizardLM](https://wizardlm.github.io)
- [x] [Open AI ChatGPT](https://openai.com/chatgpt)

01.AI Yi, LMSYS Vicuna, Meta Llama, and WizardLM are open-source models that are supported through [Ollama](https://ollama.ai).

## Docker

Clone the repository and copy the Docker Compose template:

```
git clone https://github.com/icebaker/ruby-nano-bots.git
cd ruby-nano-bots
cp docker-compose.example.yml docker-compose.yml
```

Set your provider credentials and choose your desired path for the cartridges files:

### Anthropic Claude Container

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      ANTHROPIC_API_KEY: your-api-key
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

### Cohere Command Container

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      COHERE_API_KEY: your-api-key
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

### Maritaca AI MariTalk Container

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      MARITACA_API_KEY: your-api-key
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

### Mistral AI Container

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      MISTRAL_API_KEY: your-api-key
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

### Ollama Container

Remember that your `localhost` is by default inaccessible from inside Docker. You need to either establish [inter-container networking](https://docs.docker.com/compose/networking/), use the [host's address](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host), or use the [host network](https://docs.docker.com/network/network-tutorial-host/), depending on where the Ollama server is running and your preferences.

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      OLLAMA_API_ADDRESS: http://localhost:11434
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
    # If you are running the Ollama server on your localhost:
    network_mode: host # WARNING: Be careful, this may be a security risk.
```

### OpenAI ChatGPT Container

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      OPENAI_API_KEY: your-access-token
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

### Google Gemini Container

#### Option 1: API Key (Generative Language API) Config

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      GOOGLE_API_KEY: your-api-key
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

#### Option 2: Service Account Credentials File (Vertex AI API) Config

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      GOOGLE_CREDENTIALS_FILE_PATH: /root/.config/google-credentials.json
      GOOGLE_REGION: us-east4
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./google-credentials.json:/root/.config/google-credentials.json
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

#### Option 3: Application Default Credentials (Vertex AI API) Config

```yaml
---
services:
  nano-bots:
    image: ruby:3.3.3-slim-bookworm
    command: sh -c "apt-get update && apt-get install -y --no-install-recommends build-essential libffi-dev libsodium-dev lua5.4-dev curl && curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | bash && gem install nano-bots -v 3.4.0 && bash"
    environment:
      GOOGLE_REGION: us-east4
      NANO_BOTS_ENCRYPTION_PASSWORD: UNSAFE
      NANO_BOTS_END_USER: your-user
    volumes:
      - ./your-cartridges:/root/.local/share/nano-bots/cartridges
      - ./your-state-path:/root/.local/state/nano-bots
```

#### Custom Project ID Config
If you need to manually set a Google Project ID:

```yaml
environment:
  GOOGLE_PROJECT_ID=your-project-id
```

### Running the Container

Enter the container:
```sh
docker compose run nano-bots
```

Start playing:
```sh
nb - - eval "hello"
nb - - repl

nb assistant.yml - eval "hello"
nb assistant.yml - repl
```

You can exit the REPL by typing `exit`.

## Development

```bash
bundle
rubocop -A
rspec

bundle exec ruby spec/tasks/run-all-models.rb

bundle exec ruby spec/tasks/run-model.rb spec/data/cartridges/models/openai/gpt-4-turbo.yml
bundle exec ruby spec/tasks/run-model.rb spec/data/cartridges/models/openai/gpt-4-turbo.yml stream
```

If you face issues upgrading gem versions:

```sh
bundle install --full-index
```

### Publish to RubyGems

```bash
gem build nano-bots.gemspec

gem signin

gem push nano-bots-3.4.0.gem
```
