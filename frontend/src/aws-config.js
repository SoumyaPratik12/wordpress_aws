const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: "ap-south-1_LfKHhG6qr",
      userPoolClientId: "b3v8j8rls4roj5voaq8m3d768",
      loginWith: {
        email: true,
      },
    },
  },
};

export const API_ENDPOINT = "https://s1uxwy0xfi.execute-api.ap-south-1.amazonaws.com";

export default awsConfig;
