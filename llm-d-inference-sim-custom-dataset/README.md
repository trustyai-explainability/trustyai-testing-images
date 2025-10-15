# Dataset builder and tokenizers cache
The dataset builder is used to convert conversations to a SQLite database. These are the responses that the LLM-d-inference-sim will generate reponses from. If a conversation was already had and the past messages match, the assistant response will be returned.

## Dataset builder command

```shell
python3 build_dataset.py /chats /build_artifacts/db.sqlite
```

## Build Artifacts
The build artifacts directory contains the built database and the tokenizer_cache files for the /tokenizer endpoint.
The tokenizer files can be downloaded from HuggingFace (specifically the merges.txt and tokenizer.json files) and put in a folder for that specific model. There are two supported model tokenizers here already, `Qwen2.5-1.5B-Instruct` and `qwen25-05b-instruct`.
