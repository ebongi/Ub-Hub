import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class Accountdetails extends StatefulWidget {
  const Accountdetails({super.key});

  @override
  State<Accountdetails> createState() => _AccountdetailsState();
}

class _AccountdetailsState extends State<Accountdetails> {
  String name = "Ebong Sume Joestella";
  String matricule = "SC23A569";
  String email = "sumeebong7@gmail.com";
  int phonenumber = 670021473;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Account info"), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

             Align(
              alignment: Alignment.center,
               child: CircleAvatar(
                backgroundColor:  Colors.white,
                radius: 80,
                child: Icon(Icons.person,size: 100,),
               ),
             ),
            Row(
              children: [
                const Icon(Icons.account_circle_rounded),
                SizedBox(width: 10,),
                Text(
                  "Name :",
                  style: GoogleFonts.poppins().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                name.toUpperCase(),
                style: GoogleFonts.poppins().copyWith(
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Divider(),
            Row(
              children: [
                const Icon(Iconsax.archive4),
                SizedBox(width: 10,),
                Text(
                  "Matricule :",
                  style: GoogleFonts.poppins().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                matricule.toUpperCase(),
                style: GoogleFonts.poppins().copyWith(
                  fontSize: 25,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Divider(),
            Row(
              children: [
                const Icon(Icons.email),
                SizedBox(width: 10,),
                Text(
                  "Email :",
                  style: GoogleFonts.poppins().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                email,
                style: GoogleFonts.poppins().copyWith(
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Divider(),
            Row(
              children: [
                const Icon(Icons.phone),
                const SizedBox(width: 10,),
                Text(
                  "PhoneNumber :",
                  style: GoogleFonts.poppins().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                phonenumber.toString().toUpperCase(),
                style: GoogleFonts.poppins().copyWith(
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
