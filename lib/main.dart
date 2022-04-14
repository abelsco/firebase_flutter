import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:string_validator/string_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_APIKEY'],
    appId: dotenv.env['FIREBASE_APPID'],
    messagingSenderId: dotenv.env['FIREBASE_MESSASINGSENDERID'],
    projectId: dotenv.env['FIREBASE_PROJECTID'],
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sample Firebase',
      home: FirstPageRoute(),
    );
  }
}

class FirstPageRoute extends StatefulWidget {
  const FirstPageRoute({Key? key}) : super(key: key);

  @override
  _FirstPageRouteState createState() => _FirstPageRouteState();
}

class _FirstPageRouteState extends State<FirstPageRoute> {
  // Controller para o texto
  final TextEditingController _textController = TextEditingController();

  // Referencio a collection para a que foi criada no firebase
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('db_desafio');
  Future<void> _create() async {
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                      labelText: 'Digite aqui o seu texto'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: const Text('Salvar'),
                  onPressed: () async {
                    final String? text = _textController.text;
                    // Realizo as validações do texto
                    if (text != null) {
                      if (isNumeric(text)) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                //Ficaria aqui a implementação
                                content: Text('Voce digitou um numero')));
                      }
                      // Realizo o cadastro de forma assíncrona no firebase
                      await _col.add({"text": text});
                    }

                    // Limpo a variavel
                    _textController.text = '';
                  },
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        leading: GestureDetector(
          onTap: () {
            // Implemento a logica de navegação entre telas
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondPageRoute()),
            );
          },
          child: const Icon(
            Icons.inventory_2, // ícone do botão da primeira tela
          ),
        ),
      ),
      // Corpo principal da primeira tela
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              'Bem vindo(a) ao sistema de cadastro integrado com o firebase',
            ),
            Text(
              'Utilize os botões para navegar',
            ),
          ],
        ),
      ),
      // Botão para efetuar os cadastros
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SecondPageRoute extends StatefulWidget {
  const SecondPageRoute({Key? key}) : super(key: key);

  @override
  _SecondPageRouteState createState() => _SecondPageRouteState();
}

class _SecondPageRouteState extends State<SecondPageRoute> {
  final TextEditingController _textController = TextEditingController();

  final CollectionReference _col =
      FirebaseFirestore.instance.collection('db_desafio');
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    // verifico se o meu Document possui algum texto, se possuir guardo ele
    if (documentSnapshot != null) {
      _textController.text = documentSnapshot['text'];
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                      labelText: 'Digite aqui o seu texto'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: const Text('Atualizar'),
                  onPressed: () async {
                    final String? text = _textController.text;
                    if (text != null) {
                      if (isNumeric(text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                //Ficaria aqui a implementação
                                content: Text(
                                    'Voce atualizou o dado com um numero')));
                      }

                      // Executo o update na collection de forma assíncrona
                      await _col
                          .doc(documentSnapshot!.id)
                          .update({"text": text});
                    }

                    // Limpo a variavel ambiente
                    _textController.text = '';
                  },
                )
              ],
            ),
          );
        });
  }

// Função assíncrona que realiza a exclusão do dado
  Future<void> _delete(String docId) async {
    await _col.doc(docId).delete();

    // Apenas uma mensagem informando o usuário que o dado foi excluído
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro excluído com sucesso')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.undo, // ícone da segunda tela
          ),
        ),
      ),
      // body com StreamBuilder para mostrar a ListView com os dados cadastrados (widgets)
      body: StreamBuilder(
        stream: _col.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Card(
                  margin: const EdgeInsets.all(5),
                  child: ListTile(
                    title: Text(documentSnapshot['text']),
                    subtitle: const Text('Esse foi o texto digitado'),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _update(documentSnapshot)),
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _delete(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
