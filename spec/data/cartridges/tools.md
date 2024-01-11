A cartridge is a YAML file with human-readable data that outlines the bot's goals, expected behaviors, and settings for authentication and provider utilization.

We begin with the meta section, which provides information about what this cartridge is designed for:

```yaml
meta:
  symbol: 🕛
  name: Date and Time
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
    model: gpt-4-1106-preview
```

In my API, I have set the environment variables `OPENAI_API_KEY` and `NANO_BOTS_END_USER`, which is where the values for these will come from.

Nano Bot ready; let's start adding some extra power to it.

## Random Numbers

```yml
tools:
- name: random-number
  description: Generates a random number within a given range.
  parameters:
    type: object
    properties:
      from:
        type: integer
        description: The minimum expected number for random generation.
      to:
        type: integer
        description: The maximum expected number for random generation.
    required:
      - from
      - to
```

```clj
(let [{:strs [from to]} parameters]
  (+ from (rand-int (+ 1 (- to from)))))
```

## Date and Time

```yaml
tools:
- name: date-and-time
  description: Returns the current date and time.
```

```fnl
(os.date)
```
