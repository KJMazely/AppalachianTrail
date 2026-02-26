from flask import Flask, render_template 
app = Flask(__name__) 

@app.route('/') 
def loginPage(): 
    return app.send_static_file('Login.html')

@app.route('/login', methods=['POST'])
def login():
    # Here you would add logic to verify the username and password
    # For simplicity, we will just redirect to the main page
    return app.send_static_file('MainPage.html')

@app.route('/play') 
def mainPage(): 
    return app.send_static_file('MainPage.html')


 
if __name__ == '__main__': 
    app.run(debug=True) 