import json
import csv

# Read the JSON files
with open('src/main/resources/CpcToTspiRequest/authorization-request.json', 'r') as f:
    auth_data = json.load(f)

with open('src/main/resources/CpcToTspiRequest/authorization-void-request.json', 'r') as f:
    void_data = json.load(f)

with open('src/main/resources/CpcToTspiRequest/verification-request.json', 'r') as f:
    verify_data = json.load(f)

# Extract field names from each JSON
auth_fields = set(auth_data.get('fields', {}).keys())
void_fields = set(void_data.get('fields', {}).keys())
verify_fields = set(verify_data.get('fields', {}).keys())

print(f"Auth-Request fields: {len(auth_fields)}")
print(f"VoidAuth-Request fields: {len(void_fields)}")
print(f"Verify-Request fields: {len(verify_fields)}")

# Read CSV and update it
csv_file_path = 'temp/fields-validate.csv'
rows = []

with open(csv_file_path, 'r') as f:
    reader = csv.reader(f)
    header = next(reader)
    rows.append(header)
    
    for row in reader:
        field_name = row[0].strip()
        
        # Check if field is present in each JSON
        auth_present = 'Y' if field_name in auth_fields else 'N'
        void_present = 'Y' if field_name in void_fields else 'N'
        verify_present = 'Y' if field_name in verify_fields else 'N'
        
        # Update the row with Y/N values
        updated_row = [field_name, auth_present, void_present, verify_present]
        rows.append(updated_row)

# Write updated CSV
with open(csv_file_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(rows)

print("CSV file updated successfully!")

# Print summary of results
auth_count = sum(1 for row in rows[1:] if row[1] == 'Y')
void_count = sum(1 for row in rows[1:] if row[2] == 'Y')
verify_count = sum(1 for row in rows[1:] if row[3] == 'Y')

print(f"\nSummary:")
print(f"Auth-Request: {auth_count} fields found")
print(f"VoidAuth-Request: {void_count} fields found")
print(f"Verify-Request: {verify_count} fields found")

# Print fields not found
print(f"\nFields NOT found in Auth-Request:")
for row in rows[1:]:
    if row[1] == 'N':
        print(f"  - {row[0]}")

print(f"\nFields NOT found in VoidAuth-Request:")
for row in rows[1:]:
    if row[2] == 'N':
        print(f"  - {row[0]}")

print(f"\nFields NOT found in Verify-Request:")
for row in rows[1:]:
    if row[3] == 'N':
        print(f"  - {row[0]}")

