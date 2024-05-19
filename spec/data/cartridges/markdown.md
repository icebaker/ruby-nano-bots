A cartridge is a YAML file with human-readable data that outlines the bot's goals, expected behaviors, and settings for authentication and provider utilization.

We begin with the meta section, which provides information about what this cartridge is designed for:

```yaml
meta:
  symbol: 🤖
  name: ChatGPT 4o
  author: icebaker
  version: 0.0.1
  license: CC0-1.0
  description: A helpful assistant.
```

It includes details like versioning and license.

Next, we add a behavior section that will provide the bot with a directive on how it should behave:

```yaml
behaviors:
  interaction:
    directive: You are a helpful assistant.
```

Now, we need to provide instructions on how this Nano Bot should connect with a provider, which credentials to use, and what specific configurations for the LLM are required:

```yaml
provider:
  id: openai
  credentials:
    access-token: ENV/OPENAI_API_KEY
  settings:
    user: ENV/NANO_BOTS_END_USER
    model: gpt-4o
```

In my API, I have set the environment variables `OPENAI_API_KEY` and `NANO_BOTS_END_USER`, which is where the values for these will come from.
