from django.shortcuts import redirect
from django.http import HttpResponse, HttpResponseBadRequest
from google_auth_oauthlib.flow import Flow
import os

# Get the path to the client secret JSON file
CLIENT_SECRET_FILE = os.path.join(os.path.dirname(__file__), '/Users/dhanushadurukatla/Downloads/Project R/googlealerts.json')

# Define the OAuth scopes
SCOPES = ['https://www.googleapis.com/auth/alerts']

# Define the redirect URI
REDIRECT_URI = 'http://localhost:8000/oauth2callback'

def google_login(request):
    # Initialize the OAuth flow using the client secret file
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRET_FILE,
        scopes=SCOPES,
        redirect_uri=REDIRECT_URI
    )
    
    # Generate the authorization URL and store the OAuth state
    authorization_url, state = flow.authorization_url(access_type='offline')
    request.session['oauth_state'] = state
    
    # Redirect the user to the Google OAuth consent screen
    return redirect(authorization_url)

def oauth2callback(request):
    # Retrieve the OAuth state from the session
    state = request.session.pop('oauth_state', None)
    
    # Verify the OAuth state
    if state is None or state != request.GET.get('state'):
        return HttpResponseBadRequest('Invalid state parameter')
    
    # Initialize the OAuth flow using the client secret file
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRET_FILE,
        scopes=SCOPES,
        redirect_uri=REDIRECT_URI
    )
    
    # Exchange the authorization code for OAuth tokens
    try:
        flow.fetch_token(authorization_response=request.build_absolute_uri())
        credentials = flow.credentials
    except Exception as e:
        return HttpResponseBadRequest(f'Failed to fetch tokens: {e}')
    
    # Assuming a successful response for demonstration purposes
    response = {'status': 'success', 'message': 'Alert created successfully'}
    
    # Check if the alert was successfully created
    if response.get('status') == 'success':
        return HttpResponse(response.get('message'))
    else:
        return HttpResponseBadRequest('Failed to create alert: ' + response.get('error_message', 'Unknown error'))
