from flask import Flask, json, jsonify, jsonify, make_response, redirect, render_template, request, session, url_for
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, set_access_cookies
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
    if check_user_password(username, password):
        access_token = create_access_token(identity=username)
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

@app.route('/api/users', methods=['GET'])
def get_users():
    user_list = read_all_users()
    dict = [user.to_dict() for user in user_list]
    return jsonify(dict)


 
if __name__ == '__main__': 
    app.run(debug=True) 