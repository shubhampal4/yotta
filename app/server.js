const express = require('express');
const { Kafka } = require('kafkajs');

const app = express();
const port = process.env.PORT || 3000;
const tenant = process.env.TENANT || 'unknown';
const kafkaBroker = process.env.KAFKA_BROKER || 'kafka-service:9092';

console.log(`Connecting to Kafka broker: ${kafkaBroker}`);
const kafka = new Kafka({
  clientId: `yotta-app-${tenant}`,
  brokers: [kafkaBroker]
});

const producer = kafka.producer();

app.get('/', async (req, res) => {
  res.send(`<h1>Welcome to ${tenant}'s Website</h1><p>Status: Healthy</p>`);
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Simulate a deployment event trigger
app.get('/trigger-event', async (req, res) => {
  try {
    await producer.connect();
    await producer.send({
      topic: 'deployment-events',
      messages: [
        { value: JSON.stringify({ event: 'WebsiteCreated', tenant, timestamp: new Date() }) },
      ],
    });
    res.send(`Event triggered for ${tenant}`);
  } catch (err) {
    console.error(err);
    res.status(500).send('Failed to trigger event');
  }
});

app.listen(port, () => {
  console.log(`Server running for tenant ${tenant} on port ${port}`);
});
