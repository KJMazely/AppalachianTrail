from flask import Flask, json, jsonify, jsonify, render_template, request
from flask_jwt_extended import JWTManager, create_access_token, jwt_required
from dbHandler import check_user_password, create_user, read_user_by_id, update_user_score, delete_user, read_all_users
app = Flask(__name__) 
app.config['JWT_SECRET_KEY'] = 'thisissecretkey'
jwt = JWTManager(app)


@app.route('/') 
def loginPage(): 
    return app.send_static_file('Login.html')

@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')
    if check_user_password(username, password):
        access_token = create_access_token(identity=username)
        return jsonify(access_token=access_token)
    return jsonify(error='Invalid credentials'), 401

@app.route('/play') 
@jwt_required()
def mainPage(): 
    
    return app.send_static_file('MainPage.html')

@app.route('/api/users')
def get_users():
    user_list = read_all_users()
    dict = [user.to_dict() for user in user_list]
    return jsonify(dict)


 
if __name__ == '__main__': 
    app.run(debug=True) 