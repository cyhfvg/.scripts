#!/usr/bin/env python3

import sys
import json

json_path = sys.argv[1]

with open(f"{json_path}", 'r', encoding='utf-8') as f:
    json_str = f.read()
    json_object = json.loads(json_str)
    formated_str = json.dumps(json_object, indent=5)
    formated_str = formated_str.encode('utf-8').decode('unicode_escape')
    print(formated_str)
