const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.firestore
  .document("updates/{id}")
  .onCreate((snap, context) => {

    const data = snap.data();

    const payload = {
      notification: {
        title: "Metro Update",
        body: data.message,
      }
    };

    return admin.messaging().sendToTopic("allUsers", payload);
  });