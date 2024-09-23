from cyberint.utils.logging import get_logger
from cyberint.utils.kafka import Consumer, Message, Producer

MODULE_NAME = 'cyberint.services.register_bot'
logger = get_logger(MODULE_NAME)

_stop_polling = False


def _graceful_exit_handler(signum, _frame):
    logger.info('Got termination signal: %s', signum)
    global _stop_polling  # noqa
    _stop_polling = True


async def handle_message(message: Message, producer: Producer):
    pass


async def work(consumer: Consumer, producer: Producer):
    for message in consumer:
        if _stop_polling:
            return
        await handle_message(message, producer)
        consumer.store_message_offset(message)
        if _stop_polling:
            return
