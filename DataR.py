#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 8 16:24:07 2024 by rampal
Integration of Google Sheets data extraction with Flask for dynamic opportunity pages.
"""

import gspread
from google.oauth2.service_account import Credentials
import sqlite3
import logging
from flask import Flask, render_template, abort

# Setup basic logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Initialize Flask app
app = Flask(__name__)
DATABASE = 'new_opportunities_db.db'  # Use the correct path to your SQLite database

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row  # This enables column access by name: row['column_name']
    return conn

@app.route('/opportunity/<int:id>')
def opportunity(id):
    conn = get_db_connection()
    opportunity = conn.execute('SELECT * FROM opportunities WHERE id = ?', (id,)).fetchone()
    conn.close()
    if opportunity is None:
        abort(404)
    return render_template('opportunity.html', opportunity=opportunity)

def setup_database():
    conn = sqlite3.connect(DATABASE)
    c = conn.cursor()
    try:
        # Create or update the table if it does not exist
        c.execute('''
        CREATE TABLE IF NOT EXISTS opportunities (
            Title TEXT,
            Location TEXT,
            Type TEXT,
            Description TEXT,
            Value TEXT,
            Deadline TEXT,
            Website TEXT,
            DatePosted TEXT,
            OpportunityURL TEXT
        )
        ''')
        logging.info("Table created or confirmed.")
    except Exception as e:
        logging.error(f"Error creating table: {e}")

    # Extracting data from Google Sheets
    scope = ['https://spreadsheets.google.com/feeds', 'https://www.googleapis.com/auth/drive']
    key_file_path = '/Users/rampal/Downloads/Project-R/credentials.json'  # Correct the filename
    creds = Credentials.from_service_account_file(key_file_path, scopes=scope)
    client = gspread.authorize(creds)
    sheet_id = '1jFpMWLn_emhV0roxpVYU6_yGi7-KPNWgyikv_fy1dPY'
    sheet = client.open_by_key(sheet_id)
    worksheet = sheet.get_worksheet(0)
    data = worksheet.get_all_records()

    # Insert data into the database
    for index, item in enumerate(data, start=1):
        opportunity_url = f"https://yourdomain.com/opportunities/{index}"
        insert_data = {
            'Title': item.get('Title', 'Unknown'),
            'Location': item.get('Location', 'Unknown'),
            'Type': item.get('Type', 'Unknown'),
            'Description': item.get('Description', 'Unknown'),
            'Value': item.get('Value', 'Unknown'),
            'Deadline': item.get('Deadline', 'Unknown'),
            'Website': item.get('Website', 'Unknown'),
            'DatePosted': item.get('Date Posted', 'Unknown'),
            'OpportunityURL': opportunity_url
        }
        try:
            c.execute('''
            INSERT INTO opportunities (Title, Location, Type, Description, Value, Deadline, Website, DatePosted, OpportunityURL)
            VALUES (:Title, :Location, :Type, :Description, :Value, :Deadline, :Website, :DatePosted, :OpportunityURL)
            ''', insert_data)
        except Exception as e:
            logging.error(f"Error inserting data: {e}")

    conn.commit()
    conn.close()

if __name__ == '__main__':
    setup_database()  # Ensure the database is setup and data is populated
    app.run(debug=True)  # Start the Flask application
