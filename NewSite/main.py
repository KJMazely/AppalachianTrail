from flask import Flask, json, jsonify, jsonify, make_response, redirect, render_template, request, session, url_for
from flask_jwt_extended import JWTManager, create_access_token, get_jwt_identity, jwt_required, set_access_cookies
from dbHandler import check_user_password, create_user, read_user_by_id, update_user_score, delete_user, read_all_users
app = Flask(__name__) 
app.config['SECRET_KEY'] = 'your_secret_key'  # Change this to a random secret key in production
app.config['JWT_TOKEN_LOCATION'] = ['cookies']
app.config['JWT_COOKIE_SECURE'] = False  # True in production (HTTPS)
app.config['JWT_ACCESS_COOKIE_PATH'] = '/'
jwt = JWTManager(app)


@app.route('/') 
def loginPage(): 
    return app.send_static_file('Login.html')

@app.route('/login', methods=['POST'])
def login():
    username = request.form.get('username')
    password = request.form.get('password')
    user_id = check_user_password(username, password)
    if user_id:
        access_token = create_access_token(identity=str(user_id))
        resp = make_response(redirect(url_for('mainPage')))

        # Set the access token in an HTTP-only cookie
        set_access_cookies(resp, access_token)

        return resp
    else:
        return 'Invalid username or password', 401

@app.route('/play') 
@jwt_required()
def mainPage(): 
    return app.send_static_file('MainPage.html')

@app.route('/logout')
def logout():
    resp = make_response(redirect(url_for('loginPage')))
    resp.set_cookie('access_token_cookie', '', expires=0)
    return resp

@app.route('/api/users', methods=['GET'])
def get_users():
    user_list = read_all_users()
    dict = [user.to_dict() for user in user_list]
    return jsonify(dict)

@app.route('/api/me/', methods=['GET'])
@jwt_required()
def get_current_user():
    current_user_id = get_jwt_identity()
    user = read_user_by_id(current_user_id)
    if user:
        return jsonify(user.to_dict())
    else:
        return jsonify({'error': 'User not found'}), 404

@app.route('/api/update', methods=['PUT'])
def update_score():
    current_user_id = request.json.get('id')
    print(f"Current user ID: {current_user_id}")  # Debugging line
    new_score = request.json.get('score')
    if update_user_score(current_user_id, new_score):
        return jsonify({'message': 'Score updated successfully'})
    else:
        return jsonify({'error': 'Failed to update score'}), 400

#just for testing purposes
@app.route("/protected", methods=["GET"])
@jwt_required()
def protected():
    # Access the identity of the current user with get_jwt_identity
    current_user = get_jwt_identity()
    return jsonify(logged_in_as=current_user), 
    
@app.route('/SignUp')
def signUpPage():
    return app.send_static_file('SignUp.html')


@app.route('/create', methods=['POST'])
def create_new_user():
    username =  request.form.get('username')
    password =  request.form.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password are required'}), 400
    if create_user(username, password, 0):
        return redirect(url_for('loginPage'))
    else:
        return jsonify({'error': 'Failed to create user'}), 400

if __name__ == '__main__': 
    app.run(debug=True) 