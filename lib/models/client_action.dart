/// How the workshop answered something the client asked it to do on an order or an appointment.
sealed class ClientActionOutcome {
  const ClientActionOutcome();
}

class ActionDone extends ClientActionOutcome {
  const ActionDone();
}

/// Not done, for a reason worded for the client.
class ActionRefused extends ClientActionOutcome {
  const ActionRefused(this.message);

  final String message;
}
