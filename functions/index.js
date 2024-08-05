const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();


exports.markAbsentUsers = functions.https.onSchedule("0 0 * * *", async () => {
  const companiesRef = admin.firestore().collection("RegisteredCompany");
  const companies = await companiesRef.get();

  companies.forEach((company) => {
    const usersRef = company.ref.collection("users");
    usersRef.get().then((users) => {
      users.forEach((user) => {
        const timestamp = admin.firestore.Timestamp.now();
        const dateString = timestamp.toDate().toLocaleDateString();
        const recordRef = user.ref.collection("Record").doc(dateString);
        recordRef.get().then((record) => {
          if (
            !record.exists ||
            record.get("checkIn") === "--/--" ||
            record.get("checkOut") === "--/--"
          ) {
            recordRef.set({
              date: admin.firestore.Timestamp.now(),
              checkIn: "--/--",
              checkOut: "--/--",
              status: "Absent",
            });
          }
        });
      });
    });
  });
});
