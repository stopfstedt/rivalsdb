import { FastifyPluginAsync } from "fastify";
import auth0Verify from "fastify-auth0-verify";
import fastifyPlugin from "fastify-plugin";
import { auth0Audience, auth0Domain } from "../env.js";

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: {
      aud: string[];
      iat: number;
      exp: number;
      iss: string;
      sub: string;
      azp: string;
      scope: string;
    };
  }
}

const authenticatedPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.register(auth0Verify, {
    domain: auth0Domain,
    audience: auth0Audience,
  });

  fastify.addHook("preHandler", async (req) => {
    try {
      await req.jwtVerify();
    } catch (e) {
      // noop
    }
  });
};

export const authenticated = fastifyPlugin(authenticatedPlugin);

const signInRequiredPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook("preHandler", async (req, reply) => {
    if (!req.user) {
      reply.code(401);
      return reply.send();
    }
  });
};

export const signInRequired = fastifyPlugin(signInRequiredPlugin);
