import json
import yaml
import hashlib
import argparse
from pathlib import Path
from sqlalchemy import create_engine, Column, Integer, LargeBinary, Index, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session

Base = declarative_base()

class LlmdPrompt(Base):
    """SQLAlchemy model for the llmd table."""
    __tablename__ = 'llmd'

    id = Column(Integer, primary_key=True)
    prompt_hash = Column(LargeBinary)
    gen_tokens = Column(JSON)
    n_gen_tokens = Column(Integer)

    __table_args__ = (
        Index('idx_llmd_prompt_hash', 'prompt_hash'),
        Index('idx_llmd_n_gen_tokens', 'n_gen_tokens'),
    )

def create_database(db_path):
    """Create the SQLite database with the specified schema."""
    engine = create_engine(f'sqlite:///{db_path}')
    Base.metadata.create_all(engine)
    return engine

def generate_full_prompt(messages):
    """Generate the full prompt from conversation messages."""
    full_prompt = ""
    for msg in messages[:-1]:  # Exclude the last message
        # Handle both 'human' and 'user' roles as user messages
        if msg.get('role') in ['human', 'user']:
            full_prompt += f"### user:\n{msg['content']}\n"
        elif msg.get('role') == 'assistant':
            full_prompt += f"### assistant:\n{msg['content']}\n"
    return full_prompt

def get_prompt_hash(full_prompt):
    """Generate SHA-256 hash of the prompt."""
    return hashlib.sha256(full_prompt.encode()).digest()


def extract_generated_tokens(messages):
    """Extract generated tokens from assistant messages."""
    gen_tokens = []
    for msg in messages:
        if msg.get('role') == 'assistant':
            gen_tokens.append(msg['content'])
    return gen_tokens

def process_messages(messages):
    full_prompt = generate_full_prompt(messages)
    if not full_prompt.strip() and len(messages) > 1:
        print(f"Warning: Empty prompt generated.")
        return None

    # Generate prompt hash
    prompt_hash = get_prompt_hash(full_prompt)

    # Extract generated tokens (only from the last message)
    response = messages[-1]['content'] if messages[-1].get('role') == 'assistant' else ""
    gen_tokens = response.split()

    # Count total generated tokens

    return {
        'prompt_hash': prompt_hash,
        'gen_tokens': gen_tokens,
        'n_gen_tokens': len(gen_tokens)
    }

def process_conversation_file(file_path):
    """Process a single JSON conversation file."""
    messages = None
    with open(file_path, 'r', encoding='utf-8') as f:
        data = None
        if file_path.suffix.lower() == '.yaml':
            data = yaml.safe_load(f)
        elif file_path.suffix.lower() == '.json':
            data = json.load(f)
        else:
            raise Exception(f"Unsupported file format: {file_path.suffix}")

        if isinstance(data, list):
            return list(map(process_messages, data))
        elif isinstance(data, dict):
            if 'content' in data and 'role' in data:
                # Assume the dict itself contains message data
                return [process_messages(data)]
            else:
                return list(map(process_messages, list(data.values())))

        print(f"Warning: No messages found in {file_path}")
        return None



def convert_conversations_to_sqlite(data_folder_path, db_path):
    """Convert all JSON conversation files in a folder to SQLite database."""
    # Create a database and session
    engine = create_database(db_path)
    session = Session(engine)

    data_folder = Path(data_folder_path)
    if not data_folder.exists():
        raise ValueError(f"Folder {data_folder_path} does not exist")

    processed_count = 0
    error_count = 0

    # Process all JSON and YAML files
    for conv_file in data_folder.glob('*'):
        print(f"Processing: {conv_file.name}")
        result_dicts = process_conversation_file(conv_file)
        if result_dicts:
            try:
                for result in result_dicts:
                    llmd_entry = LlmdPrompt(
                    prompt_hash=result['prompt_hash'],
                    gen_tokens=result['gen_tokens'],
                    n_gen_tokens=result['n_gen_tokens']
                )
                    session.add(llmd_entry)
                    processed_count += 1
            except Exception as e:
                print(f"Database error for {conv_file.name}: {e}")
                error_count += 1
        else:
            error_count += 1

    # Commit and close
    session.commit()
    session.close()
    
    print(f"\nConversion completed:")
    print(f"Successfully processed: {processed_count} conversations")
    print(f"Errors encountered: {error_count} conversations")
    print(f"Database saved to: {db_path}")

def main():
    parser = argparse.ArgumentParser(description='Convert JSON/YAML conversation files to SQLite database')
    parser.add_argument('data_folder_path', help='Path to folder containing conversation files')
    parser.add_argument('db_path', help='Path for output SQLite database file')
    
    args = parser.parse_args()
    
    try:
        convert_conversations_to_sqlite(args.data_folder_path, args.db_path)
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())
