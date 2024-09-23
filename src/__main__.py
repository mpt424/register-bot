import uuid
import asyncio

from cyberint.utils.logging import get_logger, exception_logger, add_filters, ContextFilter
from cyberint.utils.python_utils.context import scoped_context
from cyberint.utils.python_utils.decorators import graceful_exit
from cyberint.utils.kafka import Admin, Consumer, Producer

from cyberint.services import register_bot as module
from cyberint.services.register_bot import configuration as cfg
from cyberint.services.register_bot.context import correlation_id


MODULE_NAME = 'cyberint.services.register_bot'
logger = get_logger(MODULE_NAME)


def ensure_topic():
    admin = Admin()
    admin.ensure_topic(cfg.OUTPUT_TOPIC, cfg.OUTPUT_TOPIC_NUM_PARTITIONS, topic_config=cfg.OUTPUT_TOPIC_CONFIG)


async def main():
    while not module._stop_polling:
        consumer = Consumer(cfg.TOPICS_TO_SUBSCRIBE, cfg.CONSUMER_GROUP_ID)
        producer = Producer()
        with scoped_context(correlation_id, str(uuid.uuid4())), consumer, producer:
            await module.work(consumer, producer)


if __name__ == '__main__':
    add_filters(ContextFilter('correlation_id', correlation_id))
    with exception_logger(logger, MODULE_NAME), graceful_exit(module._graceful_exit_handler):
        ensure_topic()
        asyncio.run(main())
