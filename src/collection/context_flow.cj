package pcc_cangjie.collection

import pcc_cangjie.defs.Context
import std.sync.{Timer, CatchupStyle}
import std.collection.concurrent.LinkedBlockingQueue

public class ContextFlow {
    private let timer: Timer

    public ContextFlow(interval: Duration, public let queue: LinkedBlockingQueue<Context>,
        private let contextsIt: Iterator<Context>) {
        timer = Timer.repeat(Duration.Zero, interval, {
            => match (contextsIt.next()) {
                case Some(context) =>
                    queue.add(context)
                    println("Added context to queue: ${context}")
                case None =>
                    queue.add(Context.POISON_CONTEXT)
                    println("No more contexts to add, added POISON_CONTEXT to queue")
            }
        }, style: Burst)
    }

    public func cancel(): Unit {
        timer.cancel()
    }
}
