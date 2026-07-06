import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
{
  

  @override
  Widget build(BuildContext context) {
      return BlocProvider( //inserisco il Bloc nell albero
          create: (_) => sl<AuthBloc>(),
          child: Scaffold(
            body:  _LoginForm(),
          ),
      );
  }
  
}

class _LoginForm extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _LoginFormState();
  
}

class _LoginFormState extends State<_LoginForm>
{
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state){ //serve a mostrare un alert / navigare di pagina
        if(state is LoginSuccess) //se è andato a nuon fine 
        {
          Navigator.of(context).pushReplacementNamed("/home");
        }
        if(state is AuthErrore){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.messaggio)));
        }
      }, 
      builder: (context, state) //serve a buildare  l ui (anche quando avviene un evento)
      {
        final isLoading = state is AuthLoading; //mi serve a capire se sta in loading cosi da bloccare i campi
        return Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _telefonoController,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: "telefono"),
              ),
              const SizedBox(height: 16,),
              TextField(
                controller: _passwordController,
                enabled: !isLoading,
                decoration: InputDecoration(labelText: "password"),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: 
                  isLoading? null : () {
                    context.read<AuthBloc>().add(
                      LoginRichiesto(telefono: _telefonoController.text, password: _passwordController.text)
                      );},
                child: isLoading ? const SizedBox( width : 20, height : 20, child: CircularProgressIndicator(strokeWidth: 2),)
                  : const Text("Accedi")
              )
            ],
          ),
        );
      }
    );
  }
  
}