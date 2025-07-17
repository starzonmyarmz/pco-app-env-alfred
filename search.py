#!/usr/bin/env python3
import json
import sys
import os

def create_error_item(title, subtitle):
    return {"items": [{"uid": "error", "title": title, "subtitle": subtitle, "arg": "", "icon": {"path": "icon.png"}}]}

def get_sort_priority(title_lower, query_lower):
    if not query_lower:
        return 0
    product_name = title_lower.split(" (")[0]
    if product_name.startswith(query_lower):
        return 0
    elif query_lower in product_name:
        return 1
    elif query_lower in title_lower:
        return 2
    return 3

def main():
    query = sys.argv[1].strip() if len(sys.argv) > 1 else ""
    query_lower = query.lower()
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    items_file = os.path.join(script_dir, "items.json")
    
    try:
        with open(items_file, 'r') as f:
            items = json.load(f)
    except FileNotFoundError:
        print(json.dumps(create_error_item("items.json not found", f"Path: {items_file}")))
        return
    except json.JSONDecodeError as e:
        print(json.dumps(create_error_item("Invalid JSON", f"Error: {str(e)}")))
        return
    except Exception as e:
        print(json.dumps(create_error_item("Load error", str(e))))
        return
    
    filtered_items = []
    for item in items:
        title_lower = item["title"].lower()
        product_name = item["title"].split(" (")[0]
        
        if not query or query_lower in title_lower or query_lower in product_name.lower():
            alfred_item = {
                "uid": item["arg"],
                "title": item["title"],
                "subtitle": item["subtitle"],
                "arg": item["arg"],
                "icon": {"path": f"icons/{item['imagefile']}"},
                "match": f"{product_name} {item['title']}",
                "autocomplete": product_name,
                "_sort_priority": get_sort_priority(title_lower, query_lower)
            }
            filtered_items.append(alfred_item)
    
    filtered_items.sort(key=lambda x: (x["_sort_priority"], x["title"]))
    
    for item in filtered_items:
        del item["_sort_priority"]
    
    print(json.dumps({"items": filtered_items}))

if __name__ == "__main__":
    main()